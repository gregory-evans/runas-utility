{
  includes unit: WinAPI declarations, error codes, text constants and helpers used by run.pas.

  Conventions:
    * Mode: Objfpc with AnsiStrings enabled - all strings live in the system code page (CP_ACP).
      All wide APIs are fed via the explicit AnsiToWide() conversion - NOT UTF8Decode().
    * All WinAPI externals carry an explicit stdcall so that 32-bit builds clean up
      the stack correctly (there is no difference on 64-bit).
    * No unit sysutils: Random/Randomize (Mersenne Twister) and IntToStr/IntToHex are
      embedded below to keep the binary small.
}
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
    { Wide variant of STARTUPINFO: all string fields are wide (only CreateProcessW is used) }
    STARTUPINFO = record
        cb : DWORD;
        lpReserved : LPWSTR;
        lpDesktop : LPWSTR;
        lpTitle : LPWSTR;
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
    ERROR_NO_COMMAND                = 116;
    ERROR_UAC_DENIED                = 117;
    ERROR_COMMAND_NOT_FOUND         = 118;
    ERROR_ELEVATED_CHILD_FAILED     = 119;
    { Text resources for errors - loaded from messages.inc, replace that file to localize }
    {$i messages.inc}
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
    FILE_ATTRIBUTE_DIRECTORY = $10;
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
    { MultiByteToWideChar }
    CP_ACP = 0;   { system ANSI code page (e.g. 1251 on Russian Windows) }
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
    TXT_HELP_1 = 'RunAs Utility v1.1 (2026-11-11)'+#10#13+
                'Copyright (c) 2026 grigorii.evseev@outlook.com'+#10#13+
                'Licensed under MIT'+#10#13+
                ' '+#10#13+
                'Usage:'+#10#13;
    TXT_HELP_2 = ' [-h | -m | -M | -n* | -w] [-v] [-a] COMMAND [PARAM1 "PARAM 2" ...]'+#10#13+
                #10#13+
                'COMMAND    - Command for run'+#10#13+
                'PARAMETERS - Parameters for run command'+#10#13+
                #10#13+
                'OPTIONS:'+#10#13+
                '    -h, --hide       Run hide.'+#10#13+
                '    -m, --minimize   Run minimized.'+#10#13+
                '    -M, --maximize   Run maximized.'+#10#13+
                '    -n, --normal     Run normal. Default option.'+#10#13+
                '    -w, --nowindow   Run without console window (CREATE_NO_WINDOW).'+#10#13+
                '    -v, --verbose    Verbose output to stderr.'+#10#13+
                '    -a, --admin      Run as Administrator.'+#10#13+
                '    -?, --help       Print this help.'+#10#13+#10#13+
                '* long aliases must be used before the command only.';



{ Wide versions of WinAPI: string arguments are LPWSTR (MMF/Event names, command line) }
function CreateProcessW(lpApplicationName: LPCWSTR; lpCommandLine: LPWSTR; lpProcessAttributes, lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL; dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPCWSTR; const lpStartupInfo: TStartupInfo; var lpProcessInformation: TProcessInformation): BOOL; stdcall; external 'kernel32' name 'CreateProcessW';
function CreateFileMappingW(hFile: HANDLE; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES; flProtect: DWORD; dwMaximumSizeHigh: DWORD; dwMaximumSizeLow: DWORD; lpName: LPCWSTR): HANDLE; stdcall; external 'kernel32' name 'CreateFileMappingW';
function OpenFileMappingW(dwDesiredAccess: DWORD; bInheritHandle: WINBOOL; lpName: LPCWSTR): HANDLE; stdcall; external 'kernel32' name 'OpenFileMappingW';
function CreateEventW(lpEventAttributes: LPSECURITY_ATTRIBUTES; bManualReset: WINBOOL; bInitialState: WINBOOL; lpName: LPCWSTR): HANDLE; stdcall; external 'kernel32' name 'CreateEventW';
function OpenEventW(dwDesiredAccess: DWORD; bInheritHandle: WINBOOL; lpName: LPCWSTR): HANDLE; stdcall; external 'kernel32' name 'OpenEventW';
function GetFileAttributesW(lpFileName: LPCWSTR): DWORD; stdcall; external 'kernel32' name 'GetFileAttributesW';
function ShellExecuteExW(lpExecInfo: LPSHELLEXECUTEINFOW):Bool;stdcall;external 'shell32.dll' name 'ShellExecuteExW';
function OpenProcessToken( ProcessHandle: THandle; DesiredAccess: DWORD; var TokenHandle: THandle): BOOL; stdcall; external 'advapi32' name 'OpenProcessToken';
function GetCurrentProcess:HANDLE; stdcall; external 'kernel32' name 'GetCurrentProcess';
function GetCurrentProcessId:DWORD; stdcall; external 'kernel32' name 'GetCurrentProcessId';
function GetTokenInformation(TokenHandle: THandle; TokenInformationClass: TTokenInformationClass; TokenInformation: Pointer; TokenInformationLength: DWORD; var ReturnLength: DWORD): BOOL; stdcall; external 'advapi32' name 'GetTokenInformation';
function CloseHandle(hObject:HANDLE):WINBOOL; stdcall; external 'kernel32' name 'CloseHandle'; 
function WaitForSingleObject(hHandle:HANDLE; dwMilliseconds:DWORD):DWORD; stdcall; external 'kernel32' name 'WaitForSingleObject';
{ Handle array for WaitForMultipleObjects. IMPORTANT: on FPC 3.2.2 (i386) an external with an
  open-array parameter passes arguments incorrectly - use a pointer to a fixed-size array
  instead, as in the windows unit } 
type TWOHandleArray = array[0..MAXIMUM_WAIT_OBJECTS-1] of THandle;
     PWOHandleArray = ^TWOHandleArray;
function WaitForMultipleObjects(nCount: DWORD; const handles: PWOHandleArray; waitAll: WINBOOL; timeoutMs: DWORD): DWORD; stdcall; external 'kernel32' name 'WaitForMultipleObjects';
function GetExitCodeProcess(hProcess: THandle; var ExitCode: DWORD): BOOL; stdcall; external 'kernel32' name 'GetExitCodeProcess';
function GetLastError:DWORD; stdcall; external 'kernel32' name 'GetLastError';

function MapViewOfFile(hFileMappingObject:HANDLE; dwDesiredAccess:DWORD; dwFileOffsetHigh:DWORD; dwFileOffsetLow:DWORD; dwNumberOfBytesToMap:SIZE_T):LPVOID; stdcall; external 'kernel32' name 'MapViewOfFile';
function UnmapViewOfFile(lpBaseAddress:LPVOID):WINBOOL; stdcall; external 'kernel32' name 'UnmapViewOfFile';

function SetEvent(hEvent:HANDLE):WINBOOL; stdcall; external 'kernel32' name 'SetEvent'; 

{ All WinAPI functions are stdcall. Stated explicitly so that 32-bit builds
  clean up the stack correctly (there is no difference on 64-bit) }
function GetTickCount: DWORD; stdcall; external 'kernel32' name 'GetTickCount';
function MultiByteToWideChar(CodePage: UINT; dwFlags: DWORD; lpMultiByteStr: LPCSTR; cchMultiByte: Integer; lpWideCharStr: LPWSTR; cchWideChar: Integer): Integer; stdcall; external 'kernel32' name 'MultiByteToWideChar';
procedure PrintHelpAndExit(exitCode: WORD);
function AnsiToWide(const value: string): WideString;
function Quoted(value: string): string;
function RunCommand(creationFlags: DWORD; mode: WORD; commandLine: string): boolean;
procedure Error(exitCode: WORD);
function IsRunningAsAdmin(): boolean;
function WriteMMF(mmfHandle: THandle; mmfSize: integer; value: string): boolean;
function ReadMMF(mmfHandle: THandle; const mmfSize: integer): string;
function ShellExec(const command, parameters: string; noWindow: boolean; out procHandle: THandle): boolean;
function StringMode(mode: WORD): string;
{ Only what is actually used by run.pas - the rest of sysutils is not pulled in }
function IntToStr(Value: QWord): string;
function IntToStr(Value: DWORD): string;
function IntToHex(Value: Longint; Digits: integer): string;
function GetFileName(fullPath: string): string;
function GetProgramPart(commandLine: string): string;
function ProgramExists(commandLine: string): boolean;
{ Random number generator (Mersenne Twister, algorithm from FPC RTL sysutils).
  Own copy instead of unit sysutils - to keep the whole RTL out of the binary }
function Random(l: longint): longint;
procedure Randomize;

var
    { RNG seed }
    RandSeed: Cardinal;
    { Cached result of IsRunningAsAdmin(): the process token does not change during execution }
    adminQueried: boolean;
    adminIsAdmin: boolean;

implementation

{ Random number generator. Mersenne Twister - algorithm from FPC RTL sysutils,
  moved here to keep unit sysutils out of the binary (saves size) }

const
    { Generator constants }
    MTWIST_N = 624;
    MTWIST_M = 397;
    MTWIST_UPPER_MASK = cardinal($80000000);
    MTWIST_LOWER_MASK = cardinal($7FFFFFFF);
    MTWIST_MATRIX_A = cardinal($9908B0DF);

var
    { Internal state of the generator }
    OldRandSeed: Cardinal = 0;
    mt_state: array[0..MTWIST_N - 1] of Cardinal;
    mt_index: Cardinal = MTWIST_N + 1;

procedure Randomize();
begin
    RandSeed := GetTickCount;
end; { Randomize() }

{$R-} { Disable range/overflow checking for the generator code only }
{$Q-}

function MTWistMixBits(u, v: Cardinal): Cardinal; inline;
begin
    result := (u and MTWIST_UPPER_MASK) or (v and MTWIST_LOWER_MASK);
end; { MTWistMixBits() }

function MTWistTwist(u, v: Cardinal): Cardinal; inline;
begin
    { The construct below is equivalent to: if odd(v) then MTWIST_MATRIX_A else 0 }
    result := (MTWistMixBits(u, v) shr 1) xor (cardinal(-(v and 1)) and MTWIST_MATRIX_A);
end; { MTWistTwist() }

procedure MTWistInit(seed: Cardinal);
var i: longint;
begin
    mt_state[0] := seed;
    for i := 1 to MTWIST_N - 1 do
        mt_state[i] := cardinal(1812433253) * (mt_state[i-1] xor (mt_state[i-1] shr 30)) + i;
    { The state index must be updated }
    mt_index := MTWIST_N;
end; { MTWistInit() }

procedure MTWistUpdateState();
var count: longint;
begin
    { The first loop initializes only N-M elements (the last one is handled separately);
      the original FPC code does the same - this element's value does not affect subsequent numbers }
    for count := 0 to MTWIST_N - MTWIST_M - 1 do
        mt_state[count] := mt_state[count + MTWIST_M] xor MTWistTwist(mt_state[count], mt_state[count+1]);
    for count := MTWIST_N - MTWIST_M to MTWIST_N - 2 do
        mt_state[count] := mt_state[count + (MTWIST_M - MTWIST_N)] xor MTWistTwist(mt_state[count], mt_state[count+1]);
    mt_state[MTWIST_N-1] := mt_state[MTWIST_M-1] xor MTWistTwist(mt_state[MTWIST_N-1], mt_state[0]);
    mt_index := 0;
end; { MTWistUpdateState() }

function MTWistU32Rand(): Cardinal;
var l_index: Cardinal;
begin
    l_index := mt_index;
    inc(mt_index);
    if (RandSeed <> OldRandSeed) or (l_index >= MTWIST_N + 1) then begin
        { The seed changed - reinitialize. RandSeed is inverted so that a subsequent
          Randomize() with the same seed will reinitialize the state again }
        MTWistInit(RandSeed);
        RandSeed := not (RandSeed);
        OldRandSeed := RandSeed;
        l_index := MTWIST_N;
    end; {if}
    if l_index = MTWIST_N then begin
        MTWistUpdateState();
        l_index := 0;
        mt_index := 1;
    end; {if}
    result := mt_state[l_index];
    result := result xor (result shr 11);
    result := result xor ((result shl 7) and cardinal($9D2C5680));
    result := result xor ((result shl 15) and cardinal($EFC60000));
    result := result xor (result shr 18);
end; { MTWistU32Rand() }

function Random(l: longint): longint;
begin
    { Without this, a negative l could yield a value equal to l itself }
    if l < 0 then inc(l);
    result := longint((Int64(MTWistU32Rand()) * l) shr 32);
end; { Random() }

{$R+} { Restore range/overflow checking }
{$Q+}

{ Returns the textual representation of the mode, as used in the parameters }
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

{ Converts an ANSI string (system code page, as returned by ParamStr) to a wide string.
  NOT UTF8Decode: with AnsiStrings the strings are encoded in CP_ACP, not UTF-8 }
function AnsiToWide(const value: string): WideString;
var
    len: integer;
begin
    if value = '' then begin
        result := '';
        exit();
    end;
    { Ask for the buffer size including the terminating #0 }
    len := MultiByteToWideChar(CP_ACP, 0, PAnsiChar(value), -1, nil, 0);
    if len <= 1 then begin
        result := '';
        exit();
    end;
    SetLength(result, len - 1);
    MultiByteToWideChar(CP_ACP, 0, PAnsiChar(value), -1, PWideChar(result), len);
end; { AnsiToWide() }

{ Launches a process with elevated rights. Hidden. ShellExecuteExW.
  On success procHandle receives the handle of the launched process (owned by the caller);
  on failure procHandle = 0 } 
function ShellExec(const command, parameters: string; noWindow: boolean; out procHandle: THandle): boolean;
var
    sei: TShellExecuteInfoW;
    wPath: WideString;
    wParams: WideString;
begin
    procHandle := 0;
    FillChar(sei, SizeOf(sei), 0);
    sei.cbSize := SizeOf(sei);
    sei.Wnd := 0;
    { NOCLOSEPROCESS - to check hProcess and distinguish a successful launch from the user
      denying the UAC prompt; NO_CONSOLE - do not create a console for the elevated copy on -w }
    if noWindow then
        sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS or SEE_MASK_NO_CONSOLE
    else
        sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
    sei.lpVerb := 'runas';
    wPath := AnsiToWide(command);
    sei.lpFile := PWideChar(wPath);
    if parameters <> '' then begin
        wParams := AnsiToWide(parameters);
        sei.lpParameters := PWideChar(wParams);
    end;
    sei.nShow := SW_HIDE;
    result := ShellExecuteExW(@sei);
    { If the process was not launched (UAC denial, file not found), hProcess = 0 - treat as failure }
    if (not result) or (sei.hProcess = 0) then begin
        result := false;
    end else begin
        { Pass the process handle to the caller: it will wait for the event OR death of the child }
        procHandle := sei.hProcess;
    end;
end; { ShellExec() }

{ Exact match for DWORD (GetCurrentProcessId and friends): no implicit conversion to Longint }
function IntToStr(Value: DWORD): string;
begin
    result := IntToStr(QWord(Value));
end; { IntToStr(Value: DWORD) }

{ QWord is the base version; other overloads are not used in this project }
function IntToStr(Value: QWord): string;
begin
    System.Str(Value, result);
end; { IntToStr(Value: QWord) }

{ Digits for IntToHex }
const
    HexDigits: array[0..15] of Char = '0123456789ABCDEF';

function IntToHex(Value: Longint; Digits: integer): string;
var i: integer;
begin
    if Digits = 0 then Digits := 1;
    SetLength(result, Digits);
    for i := 0 to Digits - 1 do begin
        result[Digits - i] := HexDigits[Value and 15];
        Value := Value shr 4;
    end; {for}
    while Value <> 0 do begin
        result := HexDigits[Value and 15] + result;
        Value := Value shr 4;
    end; {while}
end; { IntToHex() }

{ Launches a command. creationFlags - CreateProcess flags: normally CREATE_NEW_CONSOLE,
  with -w - CREATE_NO_WINDOW (no console is created for the child at all) }
function RunCommand(creationFlags: DWORD; mode: WORD; commandLine: string): boolean;
var
    si: TStartupInfo;
    pi: TProcessInformation;
begin
    FillChar(si, SizeOf(si), 0);
    si.cb := SizeOf(si);
    si.dwFlags := STARTF_USESHOWWINDOW;
    si.wShowWindow := mode;
    { The command line is CP_ACP; convert to wide explicitly for CreateProcessW }
    result := CreateProcessW(nil, PWideChar(AnsiToWide(commandLine)), nil, nil, False,
                             creationFlags, nil, nil, si, pi);
end; { RunCommand() }

{ Print help and exit with the given code }
procedure PrintHelpAndExit(exitCode: WORD);
begin
    WriteLn(TXT_HELP_1 + GetFileName(ParamStr(0)) + TXT_HELP_2);
    Halt(exitCode);
end; { PrintHelpAndExit() }

{ Returns the file name from a full path (the part after the last separator) }
function GetFileName(fullPath: string): string;
var i: Integer;
begin
    for i := Length(fullPath) downto 1 do
        if (fullPath[i] = '\') or (fullPath[i] = '/') then begin
            result := Copy(fullPath, i + 1);
            Exit;
        end; {if}
    result := fullPath;
end; { GetFileName() }

{ Returns a human-readable message for an error code (single source of truth) }
function ErrorText(code: WORD): string;
begin
    case code of
        ERROR_NO_PARAMETERS : result := ERROR_NO_PARAMETERS_TEXT;
        ERROR_REQUEST_HELP : result := ERROR_REQUEST_HELP_TEXT;
        ERROR_UNDEFINED_PARAMETERS : result := ERROR_UNDEFINED_PARAMETERS_TEXT;
        ERROR_CREATE_PROCESS : result := ERROR_CREATE_PROCESS_TEXT;
        ERROR_CANT_OPEN_SECURITY_TOKEN : result := ERROR_CANT_OPEN_SECURITY_TOKEN_TEXT;
        ERROR_CANT_WRITE_MMF : result := ERROR_CANT_WRITE_MMF_TEXT;
        ERROR_CREATE_MMF : result := ERROR_CREATE_MMF_TEXT;
        ERROR_CREATE_EVENT : result := ERROR_CREATE_EVENT_TEXT;
        ERROR_ON_WAITING_EVENT : result := ERROR_ON_WAITING_EVENT_TEXT;
        ERROR_SHELL_EXECUTE : result := ERROR_SHELL_EXECUTE_TEXT;
        ERROR_READ_MMF : result := ERROR_READ_MMF_TEXT;
        ERROR_OPEN_MMF : result := ERROR_OPEN_MMF_TEXT;
        ERROR_MAP_MMF : result := ERROR_MAP_MMF_TEXT;
        ERROR_OPEN_EVENT : result := ERROR_OPEN_EVENT_TEXT;
        ERROR_SET_EVENT : result := ERROR_SET_EVENT_TEXT;
        ERROR_NO_COMMAND : result := ERROR_NO_COMMAND_TEXT;
        ERROR_UAC_DENIED : result := ERROR_UAC_DENIED_TEXT;
        ERROR_COMMAND_NOT_FOUND : result := ERROR_COMMAND_NOT_FOUND_TEXT;
        ERROR_ELEVATED_CHILD_FAILED : result := ERROR_ELEVATED_CHILD_FAILED_TEXT;
    else
        result := '(unknown error)';
    end; {case}
end; { ErrorText() }

{ Print an error code with its message and exit }
procedure Error(exitCode: WORD);
begin
    WriteLn('Error: ', exitCode, ' - ', ErrorText(exitCode));
    Halt(exitCode);
end; { Error() }

{ Extracts the program part of a command line, taking quotes into account }
function GetProgramPart(commandLine: string): string;
var i: Integer;
begin
    if (Length(commandLine) > 0) and (commandLine[1] = '"') then begin
        { Program in quotes - look for the closing quote }
        i := Pos('"', Copy(commandLine, 2, MaxInt));
        if (i = 0) then result := commandLine
            else result := Copy(commandLine, 2, i - 1);
    end else begin
        { No quotes - up to the first space }
        i := Pos(' ', commandLine);
        if (i = 0) then result := commandLine
            else result := Copy(commandLine, 1, i - 1);
    end;
end; { GetProgramPart() }

{ Checks program existence via GetFileAttributesW.
  A bare name without separators is not checked - CreateProcess resolves it through PATH itself } 
function ProgramExists(commandLine: string): boolean;
var
    part: string;
    attr: DWORD;
begin
    part := GetProgramPart(commandLine);
    if (Pos('\', part) = 0) and (Pos('/', part) = 0) then begin
        { Bare name - CreateProcess resolves it through PATH itself }
        result := True;
    end else begin
        attr := GetFileAttributesW(PWideChar(AnsiToWide(part)));
        if attr = INVALID_FILE_ATTRIBUTES then result := False
            else result := (attr and FILE_ATTRIBUTE_DIRECTORY) = 0; { do not launch a directory }
    end;
end; { ProgramExists() }

{ Wrap in quotes if the string contains spaces }
function Quoted(value: string): string;
var
    q: string = '';
begin
    if (pos(' ', value) > 0) then q := '"';
    result := q + value + q;
end; { Quoted() }

{ Checks whether the process has administrator rights }
function IsRunningAsAdmin(): Boolean;
var
    hToken: THandle;
    elevation: TOKEN_ELEVATION;
    dwSize: DWORD;
begin
    { The result is cached: repeated calls do not open the token again }
    if adminQueried then begin
        Result := adminIsAdmin;
        exit();
    end;
    adminQueried := True;
    Result := False;
    { Open the current process token with query access }
    if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
        Error(ERROR_CANT_OPEN_SECURITY_TOKEN);
    dwSize := SizeOf(TOKEN_ELEVATION);
    { Query the elevation level. TokenElevation (value 20) returns a TOKEN_ELEVATION structure
      whose TokenIsElevated field is True for an elevated token }
    if GetTokenInformation(hToken, TokenElevation, @elevation, dwSize, dwSize) then
        Result := boolean(elevation.TokenIsElevated);
    CloseHandle(hToken);
    adminIsAdmin := Result;
end; { IsRunningAsAdmin() }

{ Write to a memory-mapped file }
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
        { Copy into the shared memory as a null-terminated string (Safe) }
        Len := Length(value);
        if Len >= mmfSize then
        Len := mmfSize - 1; // leave room for #0

        { Copy the string content (no header! just characters) }
        Move(value[1], pData^, Len);
        { Append the terminating zero }
        PChar(pData)[Len] := #0;
    finally
        UnmapViewOfFile(pData);
    end;
end; { WriteMMF() }

{ Read from a memory-mapped file }
function ReadMMF(mmfHandle: THandle; const mmfSize: integer): string;
var
    pData: pointer;
begin
    pData := MapViewOfFile(mmfHandle, FILE_MAP_READ, 0, 0, mmfSize);
    if pData = nil then Error(ERROR_MAP_MMF);
    try
        result := string(PAnsiChar(pData));
    finally
        UnmapViewOfFile(pData);
    end;
end; { ReadMMF() }

end. {includes unit}
