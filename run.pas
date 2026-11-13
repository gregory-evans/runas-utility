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

var
    { Состояние приложения. Глобальные переменные }
    mode: WORD = SW_NORMAL;         { режим запуска }
    elevation: boolean = false;     { нужно повышение прав }
    command: string = '';           { команда }
    parameters: string = '';        { параметры для команды }
    commandLine: string = '';       { итоговая командная строка (команда в кавычках + параметры) }
    { Необходимые для работы значения }
    mmfName: string;
    mmfHandle: THandle = 0;
    eventName: string;
    eventHandle: THandle;

{ Запуск себя с повышенными правами }
procedure StartElevationProcess();
begin
    { Проверим, нет ли у нас уже админских прав? }
    if IsRunningAsAdmin() then begin
        { Если админские права уже есть, то просто запускаем }
        if not RunCommand(mode, commandLine) then Halt(ERROR_CREATE_PROCESS);
    end else begin { Админских прав нет }
        { Создадим уникальное имя для mmf }
        mmfName := MMF_PREFIX + inttostr(GetCurrentProcessId());
        { Создадим файл отображаемый в память (mmf) и поместим туда строку запуска }
        mmfHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, MMF_SIZE, pchar(mmfName));
        if mmfHandle = 0 then Error(ERROR_CREATE_MMF);
        try
            if not WriteMMF(mmfHandle, MMF_SIZE, commandLine) then Error(ERROR_CANT_WRITE_MMF);
            { Создадим уникальное имя для события }
            eventName := EVENT_PREFIX + inttostr(GetCurrentProcessId());
            { Создаём событие в НЕСИГНАЛЬНОМ состоянии (AutoReset = False, Initial = False) }
            eventHandle := CreateEvent(nil, False, False, pchar(eventName));
            if eventHandle = 0 then Error(ERROR_CREATE_EVENT);
            try
                { Запустим процесс. Себя через ShellExecuteEx. С необходимыми параметрами. }
                if not ShellExec(ParamStr(0), ELEVATED_MARKER + ' ' + mmfName + ' ' + eventName + ' ' + StringMode(mode)) then begin
                    { Отказ в UAC или сбой запуска — ждать событие бессмысленно, выходим сразу }
                    WriteLn(TXT_UAC_DENIED);
                    Error(ERROR_UAC_DENIED);
                end;
                { Ждем событие (дочерний процесс открыл mmf) }
                if not Waiting(eventHandle, TIMEOUT) then Error(ERROR_ON_WAITING_EVENT);
            finally
                { Освобождаем событие }
                CloseHandle(eventHandle);
            end;
        finally
            { Освобождаем mmf }
            CloseHandle(mmfHandle);
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
                'M': mode := SW_MAXIMIZE;
                'm': mode := SW_MINIMIZE;
                'h': mode := SW_HIDE;
                'n': mode := SW_NORMAL;
                'a': elevation := true;
                '?', 'H': PrintHelpAndExit(ERROR_REQUEST_HELP);
            else
                { Неизвестный флаг: до команды — ошибка, после — обычный параметр }
                if (command = '') then PrintHelpAndExit(ERROR_UNDEFINED_PARAMETERS)
                else parameters += Quoted(arg) + ' ';
            end {case}
        else 
            if (command = '') then command := arg
            else parameters += Quoted(arg) + ' ';
    end; {for}
    { Команда должна быть указана }
    if (command = '') then Error(ERROR_NO_COMMAND);
    { Собираем итоговую командную строку. Путь к программе экранируем,
      чтобы CreateProcess корректно разобрал пути с пробелами }
    commandLine := Quoted(command) + ' ' + parameters;
    { Требуется ли повышение привелегий }
    if elevation then begin
        StartElevationProcess()
    end else begin
        if not RunCommand(mode, commandLine) then Halt(ERROR_CREATE_PROCESS);
    end;
end; { normalStart() }

{ Запущены с запросом на повышение прав }
procedure ElevatedStart();
begin
    { Разберем параметры коммандной строки }
    mmfName := ParamStr(2);
    eventName := ParamStr(3);
    case ParamStr(4) of
        'n': mode := SW_NORMAL;
        'M': mode := SW_MAXIMIZE;
        'm': mode := SW_MINIMIZE;
        'h': mode := SW_HIDE;
        else mode := SW_NORMAL;
    end; {case}
    { Откроем и прочитаем mmf }
    mmfHandle := OpenFileMapping(FILE_MAP_READ, False, pchar(mmfName));
    if mmfHandle = 0 then Error(ERROR_OPEN_MMF); 
    command := ReadMMF(mmfHandle, MMF_SIZE);
    if (command = '') then Error(ERROR_READ_MMF);
    { Освободим mmf }
    CloseHandle(mmfHandle);
    { Установим Event }
    { Открываем существующий событие, созданный родителем }
    eventHandle := OpenEvent(EVENT_MODIFY_STATE, False, pchar(eventName));
    if eventHandle = 0 then Error(ERROR_OPEN_EVENT);
    if not SetEvent(eventHandle) then Error(ERROR_SET_EVENT);
    { Освободим event }
    CloseHandle(eventHandle);
    { Выполним команду }
    if not RunCommand(mode, command) then Halt(ERROR_CREATE_PROCESS);
end; { elevatedStart() }

begin
    { Запущено с повышением привелегий? }
    if (ParamStr(1) = ELEVATED_MARKER) then ElevatedStart()
    else NormalStart();
end. { run }