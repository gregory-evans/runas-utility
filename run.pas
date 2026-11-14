{ fpc -O3 -CX -XX -Xs run.pas
strip run.exe } 
{$mode Objfpc}{$H+}
program run;
uses
    includes;

const
    MMF_PREFIX = 'Local\mmf_';
    EVENT_PREFIX = 'Global\event_';
    TIMEOUT = 10000;
    MMF_SIZE = 4096;
    ELEVATED_MARKER = '--elevated';
type
    { Состояние приложения }
    TApp = record
        mode: WORD;              { режим запуска }
        elevation: boolean;      { нужно повышение прав }
        noWindow: boolean;       { не создавать консоль у цели (-w, CREATE_NO_WINDOW) }
        verbose: boolean;        { подробный вывод в stderr (-v) }
        command: string;         { команда }
        parameters: string;      { параметры для команды }
        commandLine: string;     { итоговая командная строка (команда в кавычках + параметры) }
        mmfName: string;         { имя MMF }
        mmfHandle: THandle;      { хендл MMF }
        eventName: string;       { имя события }
        eventHandle: THandle;    { хендл события }
    end;

var
    app: TApp = (mode: SW_NORMAL; elevation: False; noWindow: False; verbose: False; command: ''; parameters: '';
                 commandLine: ''; mmfName: ''; mmfHandle: 0; eventName: ''; eventHandle: 0);

{ Уникальный суффикс для имён MMF/Event: PID перерабатывается Windows,
  поэтому к нему добавляем случайную компоненту }
function UniqueSuffix(): string;
begin
    result := IntToHex(Random(MaxInt), 8);
end; { UniqueSuffix() }

{ Вывести промежуточный шаг в stderr, если включён подробный режим (-v) }
procedure VLog(const msg: string);
begin
    if app.verbose then WriteLn(StdErr, '[run] ', msg);
end; { VLog() }

{ Запустит целевую команду (поле commandLine структуры app).
  Перед запуском проверяет существование программы (ERROR_COMMAND_NOT_FOUND),
  при неудаче запуска завершится с ERROR_CREATE_PROCESS }
procedure RunTarget();
var flags: DWORD;
begin
    if not ProgramExists(app.commandLine) then begin
        WriteLn(TXT_COMMAND_NOT_FOUND);
        Error(ERROR_COMMAND_NOT_FOUND);
    end;
    { По умолчанию цель получает новую консоль; при -w — консоли не будет вовсе }
    flags := CREATE_NEW_CONSOLE;
    if app.noWindow then flags := CREATE_NO_WINDOW;
    VLog('launching target: ' + app.commandLine);
    if not RunCommand(flags, app.mode, app.commandLine) then Halt(ERROR_CREATE_PROCESS);
end; { RunTarget() }

{ Запуск себя с повышенными правами }
procedure StartElevationProcess();
var
    suffix: string;
    wFlag: string;
    elevatedProc: THandle;
    waitResult: DWORD;
    childExitCode: DWORD;
    waitHandles: TWOHandleArray;
begin
    { Проверим, нет ли у нас уже админских прав? }
    if IsRunningAsAdmin() then begin
        { Если админские права уже есть — запускаем цель напрямую }
        VLog('already elevated — running target directly');
        RunTarget();
    end else begin { Админских прав нет }
        { Создадим уникальное имя для mmf }
        suffix := UniqueSuffix();
        app.mmfName := MMF_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
        VLog('creating mmf ' + app.mmfName);
        { Создадим файл отображаемый в память (mmf) и поместим туда строку запуска }
        app.mmfHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, MMF_SIZE,
                                            PWideChar(AnsiToWide(app.mmfName)));
        if app.mmfHandle = 0 then Error(ERROR_CREATE_MMF);
        try
            if not WriteMMF(app.mmfHandle, MMF_SIZE, app.commandLine) then Error(ERROR_CANT_WRITE_MMF);
            { Создадим уникальное имя для события }
            app.eventName := EVENT_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
            VLog('creating event ' + app.eventName);
            { Создаём событие в НЕСИГНАЛЬНОМ состоянии (AutoReset = False, Initial = False) }
            app.eventHandle := CreateEventW(nil, False, False, PWideChar(AnsiToWide(app.eventName)));
            if app.eventHandle = 0 then Error(ERROR_CREATE_EVENT);
            try
                { Запустим процесс. Себя через ShellExecuteEx. С необходимыми параметрами.
                  5-й аргумент — флаг -w (1/0), дочерняя копия прочитает его в ElevatedStart }
                if app.noWindow then wFlag := '1' else wFlag := '0';
                VLog('launching elevated copy via ShellExecuteEx');
                if not ShellExec(ParamStr(0), ELEVATED_MARKER + ' ' + app.mmfName + ' ' + app.eventName + ' ' + StringMode(app.mode) + ' ' + wFlag, app.noWindow, elevatedProc) then begin
                    { Отказ в UAC или сбой запуска — ждать событие бессмысленно, выходим сразу }
                    WriteLn(TXT_UAC_DENIED);
                    Error(ERROR_UAC_DENIED);
                end;
                { Ждем: либо событие (дочерний процесс открыл mmf), либо смерть дочернего процесса.
                  Если элевированная копия умерла до сигнала — выходим сразу с 119, не дожидаясь таймаута }
                VLog('waiting for event or child death');
                waitHandles[0] := app.eventHandle;
                waitHandles[1] := elevatedProc;
                waitResult := WaitForMultipleObjects(2, @waitHandles, False, TIMEOUT);
                if waitResult = WAIT_OBJECT_0 then begin
                    { Событие установлено — дочерний процесс прочитал mmf }
                    VLog('event signaled — child read the mmf');
                end else if (waitResult = WAIT_OBJECT_0 + 1) or (WaitForSingleObject(elevatedProc, 0) = WAIT_OBJECT_0) then begin
                    { Элевированная копия завершилась до сигнала: сообщаем сразу вместо таймаута }
                    childExitCode := $FFFFFFFF;
                    GetExitCodeProcess(elevatedProc, childExitCode);
                    VLog('elevated child exited with code ' + IntToStr(childExitCode) + ' before signaling');
                    WriteLn(TXT_ELEVATED_CHILD_FAILED);
                    CloseHandle(elevatedProc);
                    Error(ERROR_ELEVATED_CHILD_FAILED);
                end else begin
                    { Таймаут: дочерний процесс жив, но событие не установил }
                    VLog('timeout waiting for event — child still alive');
                    Error(ERROR_ON_WAITING_EVENT);
                end;
                CloseHandle(elevatedProc);
            finally
                { Освобождаем событие }
                CloseHandle(app.eventHandle);
            end;
        finally
            { Освобождаем mmf }
            CloseHandle(app.mmfHandle);
        end;
    end;
end; { StartElevationProcess() } 

{ Нормальный "оригинальный" запуск }
procedure NormalStart();
var
    i: integer;
    arg: string;
begin
    { Если не переданы параметры, показываем справку и выходим }
    if ( ParamCount <= 0 ) then PrintHelpAndExit(ERROR_NO_PARAMETERS);
    { Разберем параметры командной строки и заполним 
    информацию о состоянии приложения.
    Опция — аргумент вида -X (ровно 2 символа). Длинные алиасы (--admin, --help и пр.)
    распознаются только до команды; остальные аргументы с дефисом считаются параметрами. }
    for i:=1 to ParamCount do begin
        arg := ParamStr(i);
        if (Length(arg) = 2) and (arg[1] = '-') then // found option
            case arg[2] of
                'M': app.mode := SW_MAXIMIZE;
                'm': app.mode := SW_MINIMIZE;
                'h': app.mode := SW_HIDE;
                'w': app.noWindow := true;
                'v': app.verbose := true;
                'n': app.mode := SW_NORMAL;
                'a': app.elevation := true;
                '?', 'H': PrintHelpAndExit(ERROR_REQUEST_HELP);
            else
                { Неизвестный флаг: до команды — ошибка, после — обычный параметр }
                if (app.command = '') then PrintHelpAndExit(ERROR_UNDEFINED_PARAMETERS)
                else app.parameters += Quoted(arg) + ' ';
            end {case}
        else if (app.command = '') then
            case arg of
                { Длинные алиасы опций — распознаются только до команды }
                '--normal':   app.mode := SW_NORMAL;
                '--minimize': app.mode := SW_MINIMIZE;
                '--maximize': app.mode := SW_MAXIMIZE;
                '--hide':     app.mode := SW_HIDE;
                '--nowindow': app.noWindow := true;
                '--verbose':  app.verbose := true;
                '--admin':    app.elevation := true;
                '--help':     PrintHelpAndExit(ERROR_REQUEST_HELP);
            else
                if (app.command = '') then app.command := arg
                else app.parameters += Quoted(arg) + ' ';
            end {case}
        else
            app.parameters += Quoted(arg) + ' ';
    end; {for}
    { Команда должна быть указана }
    if (app.command = '') then Error(ERROR_NO_COMMAND);
    { Собираем итоговую командную строку. Путь к программе экранируем,
      чтобы CreateProcess корректно разобрал пути с пробелами }
    app.commandLine := Quoted(app.command) + ' ' + app.parameters;
    VLog('parsed: command=[' + app.command + '] params=[' + app.parameters + ']');
    { Требуется ли повышение привилегий }
    if app.elevation then begin
        StartElevationProcess()
    end else begin
        RunTarget();
    end;
end; { normalStart() }

{ Запущены с запросом на повышение прав }
procedure ElevatedStart();
begin
    VLog('elevated mode — reading parameters');
    { Разберем параметры командной строки }
    app.mmfName := ParamStr(2);
    app.eventName := ParamStr(3);
    case ParamStr(4) of
        'n': app.mode := SW_NORMAL;
        'M': app.mode := SW_MAXIMIZE;
        'm': app.mode := SW_MINIMIZE;
        'h': app.mode := SW_HIDE;
        else app.mode := SW_NORMAL;
    end; {case}
    { 5-й аргумент — флаг -w (отсутствует в старых запусках) }
    app.noWindow := (ParamCount >= 5) and (ParamStr(5) = '1');
    { Откроем и прочитаем mmf }
    VLog('opening mmf ' + app.mmfName);
    app.mmfHandle := OpenFileMappingW(FILE_MAP_READ, False, PWideChar(AnsiToWide(app.mmfName)));
    if app.mmfHandle = 0 then Error(ERROR_OPEN_MMF); 
    app.commandLine := ReadMMF(app.mmfHandle, MMF_SIZE);
    VLog('command read from mmf: ' + app.commandLine);
    if (app.commandLine = '') then Error(ERROR_READ_MMF);
    { Освободим mmf }
    CloseHandle(app.mmfHandle);
    { Установим Event }
    VLog('signaling event ' + app.eventName);
    { Открываем существующий событие, созданный родителем }
    app.eventHandle := OpenEventW(EVENT_MODIFY_STATE, False, PWideChar(AnsiToWide(app.eventName)));
    if app.eventHandle = 0 then Error(ERROR_OPEN_EVENT);
    if not SetEvent(app.eventHandle) then Error(ERROR_SET_EVENT);
    { Освободим event }
    CloseHandle(app.eventHandle);
    { Выполним команду }
    VLog('executing target command');
    RunTarget();
end; { elevatedStart() }

begin
    Randomize; { Инициализация генератора случайных чисел для UniqueSuffix }
    { Запущено с повышением привелегий? }
    if (ParamStr(1) = ELEVATED_MARKER) then ElevatedStart()
    else NormalStart();
end. { run }
