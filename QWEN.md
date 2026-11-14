# RunAs Utility — Project Context

## Overview

A **Free Pascal** command-line utility that launches programs with optional **administrator privilege elevation via Windows UAC**. Produces a single standalone `.exe` with zero runtime dependencies.

- **Language:** Free Pascal (ObjFPC mode, `{$H+}` — AnsiString in the system code page CP_ACP)
- **Target:** Windows 32/64-bit
- **Version:** 1.0 (Copyright 2026 grigorii.evseev@outlook.com)

## Architecture

### Source Files

| Файл | Роль |
|---|---|
| `run.pas` | Main program entry point; argument parsing, flow dispatch (`NormalStart`, `ElevatedStart`, `StartElevationProcess`, `RunTarget`) |
| `includes.pas` | Unit with all Windows API declarations, type definitions, constants, and helper functions (MMF I/O, process creation, token queries) |

1. Parent parses flags → if `-a` is set and current token is not elevated, creates a named **Memory-Mapped File** (`Local\mmf_<pid>_<suffix>`) and a named **Event** (`Global\event_<pid>_<suffix>`, suffix = `UniqueSuffix()`)
2. Command line string is written into the MMF
3. A copy of itself is launched via `ShellExecuteExW` with verb `runas` and marker `--elevated`; the 5th argument carries the `-w` flag (1/0)
4. Parent waits (`WaitForMultipleObjects`, 10s timeout) on both the Event **and** the elevated copy's process handle: if the child dies before signaling → fast fail with code `119`; event signaled → success; timeout with child still alive → code `109`. Child reads the MMF, signals the Event, and executes the command

### Key Constants

- `MMF_PREFIX = 'Local\mmf_'`, `EVENT_PREFIX = 'Global\event_'`; полное имя = префикс + PID + `_` + 8 hex-цифр (`UniqueSuffix()`)
- `MMF_SIZE = 4096`, `TIMEOUT = 10000` ms
- `ELEVATED_MARKER = '--elevated'`

## Building

```bat
build.bat
```

Or manually:

```bat
fpc -O3 -CX -XX -Xs run.pas
strip run.exe          { optional, reduces binary size }
del *.o *.ppu *.a      { cleanup intermediates }
```

**Requirements:** Free Pascal Compiler (`fpc`) in PATH; `strip` is optional.

**Bitness:** `build.bat` invokes `fpc` from PATH, so the resulting binary matches the installed FPC target (i386-Win32 or x64-Win64). For an x64 binary use a 64-bit compiler in PATH.

## Running

```bat
run.exe [-h | -m | -M | -n] [-w] [-a] COMMAND [PARAM1 "PARAM 2" ...]
```

| Flag | Window mode | Description |
|---|---|---|
| `-n` | `SW_NORMAL` | Normal window (default) |
| `-m` | `SW_MINIMIZE` | Minimized to tray |
| `-M` | `SW_MAXIMIZE` | Full-screen |
| `-h` | `SW_HIDE` | Hidden launch |
| `-w` | — | No console window at all (`CREATE_NO_WINDOW`; with `-a` also `SEE_MASK_NO_CONSOLE` for the elevated copy) |
| `-v` | — | Verbose: intermediate steps of the flow are written to stderr with a `[run]` prefix |
| `-a` | — | Elevate to Administrator via UAC |
| `-?` / `-H` | — | Print help and exit (code 102) |

Short options (`-X`, exactly two characters) are recognized anywhere; long aliases (`--normal`, `--minimize`, `--maximize`, `--hide`, `--nowindow`, `--verbose`, `--admin`, `--help`) are recognized **only before the command** — after it, any dash argument belongs to the target program. The first non-option argument is the command, everything after it becomes parameters (each auto-quoted at launch/MMF write time). Flags without a command → exit code `116`.

`IsRunningAsAdmin()` caches its result: the process token cannot change during one run, so repeated calls do not re-open the token.

### Exit Codes

Range **101–119**. Key codes: `101` = no parameters, `103` = unknown flag, `104` = process creation failed, `110` = ShellExecute failed, `116` = flags given but no command, `117` = UAC denial / elevated launch failure, `118` = command not found, `119` = elevated child died before reading the command. See `README.md` for the full table.

## Testing

```bat
tests\run_tests.bat        { main test suite — 13 automated + 1 manual UAC }
tests\test_build.bat       { verifies build environment and compilation }
tests\test_parameters.bat  { parameter parsing, window modes, exit codes — 15 tests }
tests\test_elevation.bat   { UAC elevation; Test 5 auto-verifies code 117 on failed elevation; Test 6 regression for the new wait logic }
```

Tests are batch scripts that call `run.exe` directly and check exit codes / output. Elevation tests prompt for UAC approval interactively (auto-skipped when stdin is redirected). Child-process results are verified with a bounded wait loop (`ping -n 2`) because the wrapper exits immediately after spawning.

## Coding Conventions

- **Free Pascal ObjFPC mode** with `{$H+}` (AnsiString, system code page CP_ACP — not UTF-8)
- Custom Windows API declarations in `includes.pas` rather than using standard RTL units — keeps the binary self-contained and minimal
- All external WinAPI declarations carry an explicit `stdcall` calling convention (required for correct i386-Win32 builds; without it `CreateProcessA` crashes with Runtime error 216)
- ANSI (`*A`) versions of WinAPI are used for MMF/Event naming and process creation; WideChar (`*W`) for `ShellExecuteExW`, fed by the explicit `AnsiToWide()` conversion (`MultiByteToWideChar(CP_ACP, ...)`)
- Error handling via `Halt(errorCode)` with custom codes 101–119 defined in `includes.pas`
- **FPC 3.2.2 ABI pitfall:** an external function declared with an open-array parameter (`const handles: array of THandle`) silently passes arguments incorrectly on i386 — `WaitForMultipleObjects` is therefore declared with a pointer to a fixed-size array (`PWOHandleArray`, as in the RTL `windows` unit) and called with `@arr`
- No external libraries or RTL dependencies beyond `System`: even `Random`/`Randomize` (Mersenne Twister, algorithm taken from FPC's sysutils) and the needed `IntToStr`/`IntToHex` overloads are implemented in `includes.pas`, so unit `sysutils` is not linked into the binary
- Existence check before launch: `ProgramExists()` + code 118; the kernel32 `FileExistsA` export is resolved lazily via `GetProcAddress` because it is absent on this legacy system (a static import would kill the process at load time)
- Application state is kept in a single record `TApp` (`app` is the only global variable); all handles are initialised to zero

## Known Limitations

None at present. Previously documented issues are all resolved (details in `history.md`):
- UAC denial is detected (`SEE_MASK_NOCLOSEPROCESS` + `hProcess` check, code 117); if the elevated copy dies before signaling, the parent fails fast with code 119 instead of waiting out the timeout
- MMF/Event names carry a random suffix, not just PID
- Handles are released via nested `try..finally` on every failure path
- Elevation uses wide-character APIs fed by explicit CP_ACP conversion (`AnsiToWide()`); remaining `*A` calls (CreateProcess, MMF/Event names) still rely on the system code page — see README recommendation 4

## .gitignore

Excludes build artifacts (`*.exe`, `*.o`, `*.ppu`, `*.a`), temp files (`*.tmp`, `*.bak`), ctags artifacts (GPATH/GTAGS/GRTAGS), `.vscode/`, `Thumbs.db`, `*.log`.
