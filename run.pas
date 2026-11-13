{ fpc -O3 -CX -XX -Xs run.pas
strip run.exe } 
{$mode Objfpc}{$H+}
program run;
uses
    includes, sysutils;

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
        command: string;         { команда }
        parameters: string;      { параметры для команды }
        commandLine: string;     { итоговая командная строка (команда в кавычках + параметры) }
        mmfName: string;         { имя MMF }
        mmfHandle: THandle;      { хендл MMF }
        eventName: string;       { имя события }
        eventHandle: THandle;    { хендл события }
    end;

var
    app: TApp = (mode: SW_NORMAL; elevation: False; command: ''; parameters: '';
                 commandLine: ''; mmfName: ''; mmfHandle: 0; eventName: ''; eventHandle: 0);

{ Уникальный суффикс для имён MMF/Event: PID перерабатывается Windows,
  поэтому к нему добавляем случайную компоненту }
function UniqueSuffix(): string;
begin
    result := IntToHex(Random(MaxInt), 8);
end; { UniqueSuffix() }

{ Запустит целевую команду (поле commandLine структуры app);
  при неудаче завершится с ERROR_CREATE_PROCESS }
procedure RunTarget();
begin
    if not RunCommand(app.mode, app.commandLine) then Halt(ERROR_CREATE_PROCESS);
end; { RunTarget() }

{ Запуск себя с повышенными правами }
procedure StartElevationProcess();
var
    suffix: string;
begin
    { Проверим, нет ли у нас уже админских прав? }
    if IsRunningAsAdmin() then begin
        { Если админские права уже есть, то просто запускаем }
        RunTarget();
    end else begin { Админских прав нет }
        { Создадим уникальное имя для mmf }
        suffix := UniqueSuffix();
        app.mmfName := MMF_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
        { Создадим файл отображаемый в память (mmf) и поместим туда строку запуска }
        app.mmfHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, MMF_SIZE, pchar(app.mmfName));
        if app.mmfHandle = 0 then Error(ERROR_CREATE_MMF);
        try
            if not WriteMMF(app.mmfHandle, MMF_SIZE, app.commandLine) then Error(ERROR_CANT_WRITE_MMF);
            { Создадим уникальное имя для события }
            app.eventName := EVENT_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
            { Создаём событие в НЕСИГНАЛЬНОМ состоянии (AutoReset = False, Initial = False) }
            app.eventHandle := CreateEvent(nil, False, False, pchar(app.eventName));
            if app.eventHandle = 0 then Error(ERROR_CREATE_EVENT);
            try
                { Запустим процесс. Себя через ShellExecuteEx. С необходимыми параметрами. }
                if not ShellExec(ParamStr(0), ELEVATED_MARKER + ' ' + app.mmfName + ' ' + app.eventName + ' ' + StringMode(app.mode)) then begin
                    { Отказ в UAC или сбой запуска — ждать событие бессмысленно, выходим сразу }
                    WriteLn(TXT_UAC_DENIED);
                    Error(ERROR_UAC_DENIED);
                end;
                { Ждем событие (дочерний процесс открыл mmf) }
                if not Waiting(app.eventHandle, TIMEOUT) then Error(ERROR_ON_WAITING_EVENT);
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
    Опция — аргумент вида -X (ровно 2 символа). Другие аргументы с дефисом
    (например --verbose или -1) считаются параметрами команды. }
    for i:=1 to ParamCount do begin
        arg := ParamStr(i);
        if (Length(arg) = 2) and (arg[1] = '-') then // found option
            case arg[2] of
                'M': app.mode := SW_MAXIMIZE;
                'm': app.mode := SW_MINIMIZE;
                'h': app.mode := SW_HIDE;
                'n': app.mode := SW_NORMAL;
                'a': app.elevation := true;
                '?', 'H': PrintHelpAndExit(ERROR_REQUEST_HELP);
            else
                { Неизвестный флаг: до команды — ошибка, после — обычный параметр }
                if (app.command = '') then PrintHelpAndExit(ERROR_UNDEFINED_PARAMETERS)
                else app.parameters += Quoted(arg) + ' ';
            end {case}
        else 
            if (app.command = '') then app.command := arg
            else app.parameters += Quoted(arg) + ' ';
    end; {for}
    { Команда должна быть указана }
    if (app.command = '') then Error(ERROR_NO_COMMAND);
    { Собираем итоговую командную строку. Путь к программе экранируем,
      чтобы CreateProcess корректно разобрал пути с пробелами }
    app.commandLine := Quoted(app.command) + ' ' + app.parameters;
    { Требуется ли повышение привелегий }
    if app.elevation then begin
        StartElevationProcess()
    end else begin
        RunTarget();
    end;
end; { normalStart() }

{ Запущены с запросом на повышение прав }
procedure ElevatedStart();
begin
    { Разберем параметры коммандной строки }
    app.mmfName := ParamStr(2);
    app.eventName := ParamStr(3);
    case ParamStr(4) of
        'n': app.mode := SW_NORMAL;
        'M': app.mode := SW_MAXIMIZE;
        'm': app.mode := SW_MINIMIZE;
        'h': app.mode := SW_HIDE;
        else app.mode := SW_NORMAL;
    end; {case}
    { Откроем и прочитаем mmf }
    app.mmfHandle := OpenFileMapping(FILE_MAP_READ, False, pchar(app.mmfName));
    if app.mmfHandle = 0 then Error(ERROR_OPEN_MMF); 
    app.commandLine := ReadMMF(app.mmfHandle, MMF_SIZE);
    if (app.commandLine = '') then Error(ERROR_READ_MMF);
    { Освободим mmf }
    CloseHandle(app.mmfHandle);
    { Установим Event }
    { Открываем существующий событие, созданный родителем }
    app.eventHandle := OpenEvent(EVENT_MODIFY_STATE, False, pchar(app.eventName));
    if app.eventHandle = 0 then Error(ERROR_OPEN_EVENT);
    if not SetEvent(app.eventHandle) then Error(ERROR_SET_EVENT);
    { Освободим event }
    CloseHandle(app.eventHandle);
    { Выполним команду }
    RunTarget();
end; { elevatedStart() }

begin
    Randomize; { Инициализация генератора случайных чисел для UniqueSuffix }
    { Запущено с повышением привелегий? }
    if (ParamStr(1) = ELEVATED_MARKER) then ElevatedStart()
    else NormalStart();
end. { run }