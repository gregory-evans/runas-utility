{ Build: fpc -O3 -CX -XX -Xs run.pas && strip run.exe }
{
  RunAs Utility: launches a command, optionally with elevated (administrator) rights.

  Elevation protocol (parent -> elevated child):
    The parent creates two named objects with unique names (<pid> + random suffix):
      * MMF   Local\mmf_<pid>_<suffix>   - 4 KB file-mapped buffer holding the final
                                            command line as a null-terminated CP_ACP string;
      * Event Global\event_<pid>_<suffix> - auto-reset, initially UNSIGNALED.
    Then it launches itself hidden via ShellExecuteExW (verb "runas") with arguments:
      run.exe --elevated <mmfName> <eventName> <modeChar> <wFlag>
    The 5th argument is the -w flag (1/0); it is absent in older invocations.

    The parent waits on both the event and the child process handle, with a 10 second timeout:
      * event signaled            -> success (the child read the command from the MMF);
      * child died before signal  -> code ERROR_ELEVATED_CHILD_FAILED (119), fast fail;
      * timeout, child still alive-> code ERROR_ON_WAITING_EVENT (109).

    The elevated child opens and reads the MMF, signals the event, then runs the target.
    Exit codes: see the ERROR_* constants in includes.pas and README.md.
}
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
    { Application state }
    TApp = record
        mode: WORD;              { launch mode (show window) }
        elevation: boolean;      { elevation to admin rights is required }
        noWindow: boolean;       { do not create a console for the target (-w, CREATE_NO_WINDOW) }
        verbose: boolean;        { verbose output to stderr (-v) }
        command: string;         { command }
        parameters: string;      { parameters for the command }
        commandLine: string;     { final command line (quoted command + parameters) }
        mmfName: string;         { MMF name }
        mmfHandle: THandle;      { MMF handle }
        eventName: string;       { event name }
        eventHandle: THandle;    { event handle }
    end;

var
    app: TApp = (mode: SW_NORMAL; elevation: False; noWindow: False; verbose: False; command: ''; parameters: '';
                 commandLine: ''; mmfName: ''; mmfHandle: 0; eventName: ''; eventHandle: 0);

{ Unique suffix for MMF/Event names: PIDs are reused by Windows,
  so a random component is appended }
function UniqueSuffix(): string;
begin
    result := IntToHex(Random(MaxInt), 8);
end; { UniqueSuffix() }

{ Print an intermediate step to stderr if verbose mode (-v) is enabled }
procedure VLog(const msg: string);
begin
    if app.verbose then WriteLn(StdErr, '[run] ', msg);
end; { VLog() }

{ Launches the target command (app.commandLine).
  Checks program existence before launch (ERROR_COMMAND_NOT_FOUND),
  exits with ERROR_CREATE_PROCESS on failure to start }
procedure RunTarget();
var flags: DWORD;
begin
    if not ProgramExists(app.commandLine) then begin
        WriteLn(TXT_COMMAND_NOT_FOUND);
        Error(ERROR_COMMAND_NOT_FOUND);
    end;
    { By default the target gets a new console; with -w no console is created at all }
    flags := CREATE_NEW_CONSOLE;
    if app.noWindow then flags := CREATE_NO_WINDOW;
    VLog('launching target: ' + app.commandLine);
    if not RunCommand(flags, app.mode, app.commandLine) then Halt(ERROR_CREATE_PROCESS);
end; { RunTarget() }

{ Launches itself with elevated rights }
procedure StartElevationProcess();
var
    suffix: string;
    wFlag: string;
    elevatedProc: THandle;
    waitResult: DWORD;
    childExitCode: DWORD;
    waitHandles: TWOHandleArray;
begin
    { Do we already have admin rights? }
    if IsRunningAsAdmin() then begin
        { If admin rights are already present - run the target directly }
        VLog('already elevated - running target directly');
        RunTarget();
    end else begin { No admin rights }
        { Create a unique name for the mmf }
        suffix := UniqueSuffix();
        app.mmfName := MMF_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
        VLog('creating mmf ' + app.mmfName);
        { Create the file-mapped object (mmf) and place the command line in it }
        app.mmfHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, MMF_SIZE,
                                            PWideChar(AnsiToWide(app.mmfName)));
        if app.mmfHandle = 0 then Error(ERROR_CREATE_MMF);
        try
            if not WriteMMF(app.mmfHandle, MMF_SIZE, app.commandLine) then Error(ERROR_CANT_WRITE_MMF);
            { Create a unique name for the event }
            app.eventName := EVENT_PREFIX + inttostr(GetCurrentProcessId()) + '_' + suffix;
            VLog('creating event ' + app.eventName);
            { Create the event in an UNSIGNALED state (AutoReset = False, Initial = False) }
            app.eventHandle := CreateEventW(nil, False, False, PWideChar(AnsiToWide(app.eventName)));
            if app.eventHandle = 0 then Error(ERROR_CREATE_EVENT);
            try
                { Launch itself via ShellExecuteEx with the required arguments.
                  The 5th argument is the -w flag (1/0), read by the child in ElevatedStart }
                if app.noWindow then wFlag := '1' else wFlag := '0';
                VLog('launching elevated copy via ShellExecuteEx');
                if not ShellExec(ParamStr(0), ELEVATED_MARKER + ' ' + app.mmfName + ' ' + app.eventName + ' ' + StringMode(app.mode) + ' ' + wFlag, app.noWindow, elevatedProc) then begin
                    { UAC denial or launch failure - waiting for the event makes no sense, exit immediately }
                    WriteLn(TXT_UAC_DENIED);
                    Error(ERROR_UAC_DENIED);
                end;
                { Wait: either the event (the child opened the mmf) or death of the child process.
                  If the elevated copy died before signaling - exit immediately with 119, not on timeout }
                VLog('waiting for event or child death');
                waitHandles[0] := app.eventHandle;
                waitHandles[1] := elevatedProc;
                waitResult := WaitForMultipleObjects(2, @waitHandles, False, TIMEOUT);
                if waitResult = WAIT_OBJECT_0 then begin
                    { Event set - the child read the mmf }
                    VLog('event signaled - child read the mmf');
                end else if (waitResult = WAIT_OBJECT_0 + 1) or (WaitForSingleObject(elevatedProc, 0) = WAIT_OBJECT_0) then begin
                    { The elevated copy terminated before signaling: report immediately instead of waiting for the timeout }
                    childExitCode := $FFFFFFFF;
                    GetExitCodeProcess(elevatedProc, childExitCode);
                    VLog('elevated child exited with code ' + IntToStr(childExitCode) + ' before signaling');
                    WriteLn(TXT_ELEVATED_CHILD_FAILED);
                    CloseHandle(elevatedProc);
                    Error(ERROR_ELEVATED_CHILD_FAILED);
                end else begin
                    { Timeout: the child is alive but did not set the event }
                    VLog('timeout waiting for event - child still alive');
                    Error(ERROR_ON_WAITING_EVENT);
                end;
                CloseHandle(elevatedProc);
            finally
                { Release the event }
                CloseHandle(app.eventHandle);
            end;
        finally
            { Release the mmf }
            CloseHandle(app.mmfHandle);
        end;
    end;
end; { StartElevationProcess() } 

{ Regular "original" launch }
procedure NormalStart();
var
    i: integer;
    arg: string;
begin
    { If no parameters were passed, show help and exit }
    if ( ParamCount <= 0 ) then PrintHelpAndExit(ERROR_NO_PARAMETERS);
    { Parse command-line arguments and fill in the application state.
      An option is an argument of the form -X (exactly 2 characters). Long aliases
      (--admin, --help, etc.) are recognized only before the command; any other
      dash-prefixed argument is treated as a parameter of the target program. }
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
                { Unknown flag: before the command - error, after it - a regular parameter }
                if (app.command = '') then PrintHelpAndExit(ERROR_UNDEFINED_PARAMETERS)
                else app.parameters += Quoted(arg) + ' ';
            end {case}
        else if (app.command = '') then
            case arg of
                { Long option aliases - recognized only before the command }
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
    { The command must be specified }
    if (app.command = '') then Error(ERROR_NO_COMMAND);
    { Assemble the final command line. Quote the program path so that
      CreateProcess parses paths with spaces correctly }
    app.commandLine := Quoted(app.command) + ' ' + app.parameters;
    VLog('parsed: command=[' + app.command + '] params=[' + app.parameters + ']');
    { Is privilege elevation required? }
    if app.elevation then begin
        StartElevationProcess()
    end else begin
        RunTarget();
    end;
end; { normalStart() }

{ Launched with a request to elevate rights }
procedure ElevatedStart();
begin
    VLog('elevated mode - reading parameters');
    { Parse command-line arguments }
    app.mmfName := ParamStr(2);
    app.eventName := ParamStr(3);
    case ParamStr(4) of
        'n': app.mode := SW_NORMAL;
        'M': app.mode := SW_MAXIMIZE;
        'm': app.mode := SW_MINIMIZE;
        'h': app.mode := SW_HIDE;
        else app.mode := SW_NORMAL;
    end; {case}
    { The 5th argument is the -w flag (absent in older invocations) }
    app.noWindow := (ParamCount >= 5) and (ParamStr(5) = '1');
    { Open and read the mmf }
    VLog('opening mmf ' + app.mmfName);
    app.mmfHandle := OpenFileMappingW(FILE_MAP_READ, False, PWideChar(AnsiToWide(app.mmfName)));
    if app.mmfHandle = 0 then Error(ERROR_OPEN_MMF); 
    app.commandLine := ReadMMF(app.mmfHandle, MMF_SIZE);
    VLog('command read from mmf: ' + app.commandLine);
    if (app.commandLine = '') then Error(ERROR_READ_MMF);
    { Release the mmf }
    CloseHandle(app.mmfHandle);
    { Set the event }
    VLog('signaling event ' + app.eventName);
    { Open the existing event created by the parent }
    app.eventHandle := OpenEventW(EVENT_MODIFY_STATE, False, PWideChar(AnsiToWide(app.eventName)));
    if app.eventHandle = 0 then Error(ERROR_OPEN_EVENT);
    if not SetEvent(app.eventHandle) then Error(ERROR_SET_EVENT);
    { Release the event }
    CloseHandle(app.eventHandle);
    { Execute the command }
    VLog('executing target command');
    RunTarget();
end; { elevatedStart() }

begin
    Randomize; { Initialize the random number generator for UniqueSuffix }
    { Launched in elevated mode? }
    if (ParamStr(1) = ELEVATED_MARKER) then ElevatedStart()
    else NormalStart();
end. { run }
