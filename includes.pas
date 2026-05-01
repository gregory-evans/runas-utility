{$mode Objfpc}{$H+}
{$PACKRECORDS C}  
unit includes;
interface

type 
    LPBYTE = pbyte; 
    PByte  = ^Byte;
    WINBOOL = longbool;
    BOOL = WINBOOL;
    LPVOID  = pointer;
    LPCVOID = pointer;
    UCHAR = byte;
    WCHAR = WideChar;
    UINT   = cardinal;
    ULONG  = cardinal;
    USHORT = word;
    {$ifdef CPU64}
        HANDLE = QWord;
        THandle = QWord;
        ULONG_PTR = QWord;
    {$else CPU64}
        HANDLE = DWord;
        THandle = DWord;
        ULONG_PTR = DWord;
    {$endif CPU64}   
    LPSTR = Pchar;
    LPCSTR  = Pchar;
    {$ifdef UNICODE}
        LPTCH  = Pwidechar;
        LPTSTR = Pwidechar;
    {$else}
        LPTCH  = Pchar;
        LPTSTR = Pchar;
    {$endif} 
    LPWCH  = Pwidechar;
    LPWSTR = Pwidechar;
    HWND = HANDLE;
    LPCWSTR = Pwidechar;
    HINST = HANDLE; 
    HKEY = HANDLE;
    PROCESS_INFORMATION = record
        hProcess : HANDLE;
        hThread : HANDLE;
        dwProcessId : DWORD;
        dwThreadId : DWORD;
    end;
    LPPROCESS_INFORMATION = ^PROCESS_INFORMATION;
    _PROCESS_INFORMATION = PROCESS_INFORMATION;
    TPROCESSINFORMATION = PROCESS_INFORMATION;
    PPROCESSINFORMATION = ^PROCESS_INFORMATION;
    STARTUPINFO = record
        cb : DWORD;
        {$ifdef Unicode}
            lpReserved : LPWSTR;
            lpDesktop : LPWSTR;
            lpTitle : LPWSTR;
        {$else}
            lpReserved : LPSTR;
            lpDesktop : LPSTR;
            lpTitle : LPSTR;
        {$endif} 
        dwX : DWORD;
        dwY : DWORD;
        dwXSize : DWORD;
        dwYSize : DWORD;
        dwXCountChars : DWORD;
        dwYCountChars : DWORD;
        dwFillAttribute : DWORD;
        dwFlags : DWORD;
        wShowWindow : WORD;
        cbReserved2 : WORD;
        lpReserved2 : LPBYTE;
        hStdInput : HANDLE;
        hStdOutput : HANDLE;
        hStdError : HANDLE;
    end;
    LPSTARTUPINFO = ^STARTUPINFO;
    _STARTUPINFO  = STARTUPINFO;
    TSTARTUPINFO  = STARTUPINFO;
    PSTARTUPINFO  = ^STARTUPINFO;
    SECURITY_ATTRIBUTES = record
        nLength : DWORD;
        lpSecurityDescriptor : LPVOID;
        bInheritHandle : WINBOOL;
    end;
    LPSECURITY_ATTRIBUTES = ^SECURITY_ATTRIBUTES;
    _SECURITY_ATTRIBUTES = SECURITY_ATTRIBUTES;
    TSECURITYATTRIBUTES = SECURITY_ATTRIBUTES;
    PSECURITYATTRIBUTES = ^SECURITY_ATTRIBUTES;
    TOKEN_INFORMATION_CLASS = (
        TokenUser = 1,
        TokenGroups,
        TokenPrivileges,
        TokenOwner,
        TokenPrimaryGroup,
        TokenDefaultDacl,
        TokenSource,
        TokenType,
        TokenImpersonationLevel,
        TokenStatistics,
        TokenRestrictedSids,
        TokenSessionId,
        TokenGroupsAndPrivileges,
        TokenSessionReference,
        TokenSandBoxInert,
        TokenAuditPolicy,
        TokenOrigin,
        TokenElevationType,
        TokenLinkedToken,
        TokenElevation,
        TokenHasRestrictions,
        TokenAccessInformation,
        TokenVirtualizationAllowed,
        TokenVirtualizationEnabled,
        TokenIntegrityLevel,
        TokenUIAccess,
        TokenMandatoryPolicy,
        TokenLogonSid,
        MaxTokenInfoClass  // MaxTokenInfoClass should always be the last enum
    );
    _TOKEN_INFORMATION_CLASS = TOKEN_INFORMATION_CLASS;
    TTokenInformationClass   = TOKEN_INFORMATION_CLASS;
    _TOKEN_ELEVATION = record
        TokenIsElevated: DWORD;
    end;
    TOKEN_ELEVATION = _TOKEN_ELEVATION;
    TTokenElevation = _TOKEN_ELEVATION;
    PTokenElevation = ^TTokenElevation;
    _SHELLEXECUTEINFOW       = record
                                   cbSize : DWORD;
                                   fMask : ULONG;
                                   wnd : HWND;
                                   lpVerb : lpcwstr;
                                   lpFile : lpcwstr;
                                   lpParameters : lpcwstr;
                                   lpDirectory : lpcwstr;
                                   nShow : longint;
                                   hInstApp : HINST;
                                   lpIDList : LPVOID;
                                   lpClass : LPCWSTR;
                                   hkeyClass : HKEY;
                                   dwHotKey : DWORD;
                                   DUMMYUNIONNAME : record
                                                      case longint of
                                                       0 : ( hIcon : HANDLE );
                                                       1 : ( hMonitor : HANDLE );
                                                      end;
                                   hProcess : HANDLE;
                                  end;
       SHELLEXECUTEINFOW        = _SHELLEXECUTEINFOW;
       TSHELLEXECUTEINFOW       = _SHELLEXECUTEINFOW;
       LPSHELLEXECUTEINFOW      = ^_SHELLEXECUTEINFOW;

const 
    SW_HIDE = 0;
    SW_MAXIMIZE = 3;
    SW_MINIMIZE = 6;
    SW_NORMAL = 1;
    SW_RESTORE = 9;
    SW_SHOW = 5;
    SW_SHOWDEFAULT = 10;
    SW_SHOWMAXIMIZED = 3;
    SW_SHOWMINIMIZED = 2;
    SW_SHOWMINNOACTIVE = 7;
    SW_SHOWNA = 8;
    SW_SHOWNOACTIVATE = 4;
    SW_SHOWNORMAL = 1;
    { CreateProcess  }
    CREATE_NEW_CONSOLE = 16;
    CREATE_NEW_PROCESS_GROUP = 512;
    CREATE_SUSPENDED = 4;
    STACK_SIZE_PARAM_IS_A_RESERVATION = $10000;
    DEBUG_PROCESS = 1;
    DEBUG_ONLY_THIS_PROCESS = 2;
    DETACHED_PROCESS = 8;
    HIGH_PRIORITY_CLASS = 128;
    IDLE_PRIORITY_CLASS = 64;
    NORMAL_PRIORITY_CLASS = 32;
    REALTIME_PRIORITY_CLASS = 256;
    CREATE_UNICODE_ENVIRONMENT        = $00000400;
    CREATE_SEPARATE_WOW_VDM           = $00000800;
    CREATE_SHARED_WOW_VDM             = $00001000;
    CREATE_FORCEDOS                   = $00002000;
    BELOW_NORMAL_PRIORITY_CLASS       = $00004000;
    ABOVE_NORMAL_PRIORITY_CLASS       = $00008000;
    INHERIT_PARENT_AFFINITY           = $00010000;
    INHERIT_CALLER_PRIORITY           = $00020000;    // Deprecated
    CREATE_PROTECTED_PROCESS          = $00040000;
    EXTENDED_STARTUPINFO_PRESENT      = $00080000;
    PROCESS_MODE_BACKGROUND_BEGIN     = $00100000;
    PROCESS_MODE_BACKGROUND_END       = $00200000;
    CREATE_BREAKAWAY_FROM_JOB         = $01000000;
    CREATE_PRESERVE_CODE_AUTHZ_LEVEL  = $02000000;
    CREATE_DEFAULT_ERROR_MODE         = $04000000;
    CREATE_NO_WINDOW                  = $08000000;
    PROFILE_USER                      = $10000000;
    PROFILE_KERNEL                    = $20000000;
    PROFILE_SERVER                    = $40000000;
    CREATE_IGNORE_SYSTEM_DEFAULT      = $80000000; 
    SEE_MASK_CLASSNAME       = $00000001;
    SEE_MASK_CLASSKEY        = $00000003;
    SEE_MASK_IDLIST          = $00000004;
    SEE_MASK_INVOKEIDLIST    = $0000000c;
    SEE_MASK_ICON            = $00000010;
    SEE_MASK_HOTKEY          = $00000020;
    SEE_MASK_NOCLOSEPROCESS  = $00000040;
    SEE_MASK_CONNECTNETDRV   = $00000080;
    SEE_MASK_FLAG_DDEWAIT    = $00000100;
    SEE_MASK_DOENVSUBST      = $00000200;
    SEE_MASK_FLAG_NO_UI      = $00000400;
    SEE_MASK_UNICODE         = $00004000;
    SEE_MASK_NO_CONSOLE      = $00008000;
    SEE_MASK_ASYNCOK         = $00100000;
    SEE_MASK_HMONITOR        = $00200000;
    SEE_MASK_NOQUERYCLASSSTORE= $01000000;
    SEE_MASK_WAITFORINPUTIDLE= $02000000;
    SEE_MASK_FLAG_LOG_USAGE  = $04000000;
    { STARTUPINFO structure  }
    STARTF_USESHOWWINDOW = 1;
    STARTF_USEPOSITION = 4;
    STARTF_USESIZE = 2;
    STARTF_USECOUNTCHARS = 8;
    STARTF_USEFILLATTRIBUTE = 16;
    STARTF_RUNFULLSCREEN = 32;
    STARTF_FORCEONFEEDBACK = 64;
    STARTF_FORCEOFFFEEDBACK = 128;
    STARTF_USESTDHANDLES = 256;
    STARTF_USEHOTKEY = 512; 
    { ERRORS LIST }
    ERROR_NO_PARAMETERS             = 101;
    ERROR_REQUEST_HELP              = 102;
    ERROR_UNDEFINED_PARAMETERS      = 103;
    ERROR_CREATE_PROCESS            = 104;
    ERROR_CANT_OPEN_SECURITY_TOKEN  = 105;
    ERROR_CANT_WRITE_MMF            = 106;
    ERROR_CREATE_MMF                = 107;
    ERROR_CREATE_EVENT              = 108;
    ERROR_ON_WAITING_EVENT          = 109;
    ERROR_SHELL_EXECUTE             = 110;
    ERROR_READ_MMF                  = 111;
    ERROR_OPEN_MMF                  = 112;
    ERROR_MAP_MMF                   = 113;
    ERROR_OPEN_EVENT                = 114;
    ERROR_SET_EVENT                 = 115;
    { OpenProcessToken  }
    TOKEN_ADJUST_DEFAULT = 128;
    TOKEN_ADJUST_GROUPS = 64;
    TOKEN_ADJUST_PRIVILEGES = 32;
    TOKEN_ALL_ACCESS = $f00ff;
    TOKEN_ASSIGN_PRIMARY = 1;
    TOKEN_DUPLICATE = 2;
    TOKEN_EXECUTE = $20000;
    TOKEN_IMPERSONATE = 4;
    TOKEN_QUERY = 8;
    TOKEN_QUERY_SOURCE = 16;
    TOKEN_READ = $20008;
    TOKEN_WRITE = $200e0;  
    { INVALIDS VALUES }
    INVALID_HANDLE_VALUE = HANDLE(-1);
    INVALID_FILE_SIZE    = DWORD(-1);
    INVALID_SET_FILE_POINTER = DWORD(-1);
    INVALID_FILE_ATTRIBUTES  = DWORD(-1);
    { CreateFileMapping, VirtualAlloc, VirtualFree, VirtualProtect  }
    SEC_COMMIT = 134217728;
    SEC_IMAGE = 16777216;
    SEC_NOCACHE = 268435456;
    SEC_RESERVE = 67108864;
    PAGE_READONLY = 2;
    PAGE_READWRITE = 4;
    PAGE_WRITECOPY = 8;
    PAGE_EXECUTE = 16;
    PAGE_EXECUTE_READ = 32;
    PAGE_EXECUTE_READWRITE = 64;
    PAGE_EXECUTE_WRITECOPY = 128;
    PAGE_GUARD = 256;
    PAGE_NOACCESS = 1;
    PAGE_NOCACHE = 512;
    MEM_COMMIT = 4096;
    MEM_FREE = 65536;
    MEM_RESERVE = 8192;
    MEM_IMAGE = 16777216;
    MEM_MAPPED = 262144;
    MEM_PRIVATE = 131072;
    MEM_DECOMMIT = 16384;
    MEM_RELEASE = 32768;
    MEM_TOP_DOWN = 1048576;
    MEM_RESET        = $80000;
    MEM_WRITE_WATCH  = $200000;
    MEM_PHYSICAL     = $400000;
    MEM_LARGE_PAGES  = $20000000;
    MEM_4MB_PAGES    = dword($80000000);
    EXCEPTION_GUARD_PAGE = $80000001;
    SECTION_EXTEND_SIZE = $10;
    SECTION_MAP_READ = $4;
    SECTION_MAP_WRITE = $2;
    SECTION_QUERY = $1;
    SECTION_ALL_ACCESS = $f001f;
    { DuplicateHandle, MapViewOfFile  }
    DUPLICATE_CLOSE_SOURCE = 1;
    DUPLICATE_SAME_ACCESS = 2;
    FILE_MAP_ALL_ACCESS = $f001f;
    FILE_MAP_READ = 4;
    FILE_MAP_WRITE = 2;
    FILE_MAP_COPY = 1;
    MUTEX_ALL_ACCESS = $1f0001;
    MUTEX_MODIFY_STATE = 1;
    SYNCHRONIZE = $100000;
    SEMAPHORE_ALL_ACCESS = $1f0003;
    SEMAPHORE_MODIFY_STATE = 2;
    EVENT_ALL_ACCESS = $1f0003;
    EVENT_MODIFY_STATE = 2;
    KEY_ALL_ACCESS = $f003f;
    KEY_CREATE_LINK = 32;
    KEY_CREATE_SUB_KEY = 4;
    KEY_ENUMERATE_SUB_KEYS = 8;
    KEY_EXECUTE = $20019;
    KEY_NOTIFY = 16;
    KEY_QUERY_VALUE = 1;
    KEY_READ = $20019;
    KEY_SET_VALUE = 2;
    KEY_WOW64_64KEY = $0100;
    KEY_WOW64_32KEY = $0200;
    KEY_WRITE = $20006;
    PROCESS_ALL_ACCESS = $1fFfff;
    PROCESS_TERMINATE                 = $0001;
    PROCESS_CREATE_THREAD             = $0002;
    PROCESS_SET_SESSIONID             = $0004;
    PROCESS_VM_OPERATION              = $0008;
    PROCESS_VM_READ                   = $0010;
    PROCESS_VM_WRITE                  = $0020;
    PROCESS_DUP_HANDLE                = $0040;
    PROCESS_CREATE_PROCESS            = $0080;
    PROCESS_SET_QUOTA                 = $0100;
    PROCESS_SET_INFORMATION           = $0200;
    PROCESS_QUERY_INFORMATION         = $0400;
    PROCESS_SUSPEND_RESUME            = $0800;
    PROCESS_QUERY_LIMITED_INFORMATION = $1000;
    PROCESS_SET_LIMITED_INFORMATION   = $2000;
    { MsgWaitForMultipleObjects, WaitForMultipleObjectsEx  }
    WAIT_OBJECT_0 = 0;
    WAIT_ABANDONED_0 = $80;
    WAIT_TIMEOUT = $102;
    WAIT_IO_COMPLETION = $c0;
    WAIT_ABANDONED = $80;
    WAIT_FAILED = $ffffffff;
    MAXIMUM_WAIT_OBJECTS = $40;
    MAXIMUM_SUSPEND_COUNT = $7f;
    { TEXTS }
    TXT_HELP_1 = 'RunAs Utility v1.0'+#10#13+
                'Copyright (c) 2026 grigorii.evseev@outlook.com'+#10#13+
                ' '+#10#13+
                'Usage:'+#10#13;
    TXT_HELP_2 = ' [-h | -m | -M | -n* | -?] [-a] COMMAND [PARAM1 "PARAM 2" ...]'+#10#13+
                #10#13+
                'COMMAND    - Command for run'+#10#13+
                'PARAMETERS - Parameters for run command'+#10#13+
                #10#13+
                'OPTIONS:'+#10#13+
                '    -h  Run hide.'+#10#13+
                '    -m  Run minimized.'+#10#13+
                '    -M  Run maximized.'+#10#13+
                '    -n  Run normal. Default option.'+#10#13+
                '    -a  Run as Administrator.'+#10#13+
                '    -?  Print help.';


function CreateProcess(lpApplicationName: PChar; lpCommandLine: PChar; lpProcessAttributes, lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL; dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: PChar; const lpStartupInfo: TStartupInfo; var lpProcessInformation: TProcessInformation ): BOOL; external 'kernel32' name 'CreateProcessA';
function ShellExecuteExW(lpExecInfo: LPSHELLEXECUTEINFOW):Bool;external 'shell32.dll' name 'ShellExecuteExW';
function OpenProcessToken( ProcessHandle: THandle; DesiredAccess: DWORD; var TokenHandle: THandle): BOOL; external 'advapi32' name 'OpenProcessToken';
function GetCurrentProcess:HANDLE; external 'kernel32' name 'GetCurrentProcess';
function GetCurrentProcessId:DWORD; external 'kernel32' name 'GetCurrentProcessId';
function GetTokenInformation(TokenHandle: THandle; TokenInformationClass: TTokenInformationClass; TokenInformation: Pointer; TokenInformationLength: DWORD; var ReturnLength: DWORD): BOOL; external 'advapi32' name 'GetTokenInformation';
function PathFindFileNameA(pPath: LPCSTR): LPCSTR; stdcall; external 'shlwapi.dll' name 'PathFindFileNameA';
function CloseHandle(hObject:HANDLE):WINBOOL; external 'kernel32' name 'CloseHandle'; 
function WaitForSingleObject(hHandle:HANDLE; dwMilliseconds:DWORD):DWORD; external 'kernel32' name 'WaitForSingleObject';
function GetLastError:DWORD; external 'kernel32' name 'GetLastError';
function CreateFileMapping(hFile:HANDLE; lpFileMappingAttributes:LPSECURITY_ATTRIBUTES; flProtect:DWORD; dwMaximumSizeHigh:DWORD; dwMaximumSizeLow:DWORD; lpName:LPCSTR):HANDLE; external 'kernel32' name 'CreateFileMappingA'; 
function OpenFileMapping(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; lpName:LPCSTR):HANDLE; external 'kernel32' name 'OpenFileMappingA';
function MapViewOfFile(hFileMappingObject:HANDLE; dwDesiredAccess:DWORD; dwFileOffsetHigh:DWORD; dwFileOffsetLow:DWORD; dwNumberOfBytesToMap:SIZE_T):LPVOID; external 'kernel32' name 'MapViewOfFile';
function UnmapViewOfFile(lpBaseAddress:LPVOID):WINBOOL; external 'kernel32' name 'UnmapViewOfFile';
function CreateEvent(lpEventAttributes:LPSECURITY_ATTRIBUTES; bManualReset:WINBOOL; bInitialState:WINBOOL; lpName:LPCSTR):HANDLE; external 'kernel32' name 'CreateEventA'; 
function OpenEvent(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; lpName:LPCSTR):HANDLE; external 'kernel32' name 'OpenEventA';
function SetEvent(hEvent:HANDLE):WINBOOL; external 'kernel32' name 'SetEvent'; 
procedure PrintHelpAndExit(exitCode: WORD);
function Quoted(value: string): string;
function RunCommand(mode: WORD; commandLine: string): boolean;
procedure Error(exitCode: WORD);
function IsRunningAsAdmin(): boolean;
function WriteMMF(mmfHandle: THandle; mmfSize: integer; value: string): boolean;
function ReadMMF(mmfHandle: THandle; const mmfSize: integer): string;
function Waiting(event: THandle; const TIMEOUT: integer): boolean;
function ShellExec(const command, parameters: string): boolean;
function StringMode(mode: WORD): string;
function IntToStr(Value: Longint): string;
function IntToStr(Value: Int64): string;
function IntToStr(Value: QWord): string;
function GetFileName(fullPath: string): string;

implementation

{ Возвращает тстроковое представление режима, как в параметрах }
function StringMode(mode: WORD): string;
begin
    case mode of
        SW_MAXIMIZE : result := 'M';
        SW_MINIMIZE : result := 'm';
        SW_HIDE     : result := 'h';
        SW_NORMAL   : result := 'n';
        else          result := 'n';
    end; {case}
end; { StringMode() }

{ Запуск процесса с повышением прав. Скрыто. ShellExecuteExW }
function ShellExec(const command, parameters: string): boolean;
var
    sei: TShellExecuteInfoW;
    wPath: WideString;
    wParams: WideString;
begin
    FillChar(sei, SizeOf(sei), 0);
    sei.cbSize := SizeOf(sei);
    sei.Wnd := 0;
    sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI;
    sei.lpVerb := 'runas';
    wPath := UTF8Decode(command);
    sei.lpFile := PWideChar(wPath);
    if parameters <> '' then begin
        wParams := UTF8Decode(parameters);
        sei.lpParameters := PWideChar(wParams);
    end;
    sei.nShow := SW_HIDE;
    ShellExecuteExW(@sei);
    result := (GetLastError() = 0);
end; { ShellExec() }

{ Ожидание события }
function Waiting(event: THandle; const TIMEOUT: integer): boolean;
begin
    result := (WaitForSingleObject(event, TIMEOUT) = WAIT_OBJECT_0);
end; { Waiting() }

{ IntToStr }
function IntToStr(Value: Longint): string;
begin
    System.Str(Value, Result);
end; { IntToStr(Value: Longint) }
{ int64 }
function IntToStr(Value: Int64): string;
begin
    System.Str(Value, Result);
end; { IntToStr(Value: Int64) } 
{ QWord }
function IntToStr(Value: QWord): string;
begin
    System.Str(Value, Result);
end; { IntToStr(Value: QWord) }

{ Запустить команду }
function RunCommand(mode: WORD; commandLine: string): boolean;
var
    si: TStartupInfo;
    pi: TProcessInformation;
begin
    FillChar(si, SizeOf(si), 0);
    si.cb := SizeOf(si);
    si.dwFlags := STARTF_USESHOWWINDOW;
    si.wShowWindow := mode;
    result := CreateProcess(nil, PChar(commandLine), nil, nil, False,
                            CREATE_NEW_CONSOLE, nil, nil, si, pi);
end; { RunCommand() }

{ Вывести помошь и выйти с кодом возврата }
procedure PrintHelpAndExit(exitCode: WORD);
begin
    WriteLn(TXT_HELP_1 + GetFileName(ParamStr(0)) + TXT_HELP_2);
    Halt(exitCode);
end; { PrintHelpAndExit() }

{ Вернуть имя файла из полного пути }
function GetFileName(fullPath: string): string;
begin
    result := string(PathFindFileNameA(PAnsiChar(fullPath)))
end; { GetFileName() }

{ Вывести ошибку и выйти }
procedure Error(exitCode: WORD);
begin
    WriteLn('Error: ', exitCode);
    Halt(exitCode);
end; { Error() }

{ Установить кавычки, если строка содержит пробелы }
function Quoted(value: string): string;
var
    q: string = '';
begin
    if (pos(' ', value) > 0) then q := '"';
    result := q + value + q;
end; { Quoted() }

{ Проверяет на администраторские рпава }
function IsRunningAsAdmin(): Boolean;
var
    hToken: THandle;
    elevation: TOKEN_ELEVATION;
    dwSize: DWORD;
begin
    Result := False;
    { Открываем токен текущего процесса с правом на запрос информации [citation:3][citation:7]}
    if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
        Error(ERROR_CANT_OPEN_SECURITY_TOKEN);
    dwSize := SizeOf(TOKEN_ELEVATION);
    { Запрашиваем информацию об уровне повышения привилегий [citation:6][citation:7]
      TokenElevation (значение 20) возвращает структуру TOKEN_ELEVATION,
      где поле TokenIsElevated = True, если токен повышенный [citation:8] }
    if GetTokenInformation(hToken, TokenElevation, @elevation, dwSize, dwSize) then
        Result := boolean(elevation.TokenIsElevated);
    CloseHandle(hToken);
end; { IsRunningAsAdmin() }

{ Запись в файл в памяти }
function WriteMMF(mmfHandle: THandle; mmfSize: integer; value: string): boolean;
var
    pData: pointer;
    Len: integer;
begin
    result := true;
    pData := MapViewOfFile(mmfHandle, FILE_MAP_ALL_ACCESS, 0, 0, mmfSize);
    if pData = nil then begin
        result := false;
        exit();
    end;
    try
        { Копируем в общую память как нуль-терминированную строку (Safe) }
        Len := Length(value);
        if Len >= mmfSize then
        Len := mmfSize - 1; // оставляем место под #0

        { Копируем содержимое строки (без заголовка! просто символы) }
        Move(value[1], pData^, Len);
        { Добавляем завершающий ноль }
        PChar(pData)[Len] := #0;
    finally
        UnmapViewOfFile(pData);
    end;
end; { WriteMMF() }

{ Чтение из файла в памяти }
function ReadMMF(mmfHandle: THandle; const mmfSize: integer): string;
var
    pData: pointer;
begin
    pData := MapViewOfFile(mmfHandle, FILE_MAP_READ, 0, 0, mmfSize);
    if pData = nil then Error(ERROR_MAP_MMF);
    try
        result := StrPas(PChar(pData)); // безопасно, пока данные содержат #0 в конце
    finally
        UnmapViewOfFile(pData);
    end;
end; { ReadMMF() }

end. {includes unit}