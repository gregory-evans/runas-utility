# RunAs Utility — Project Context

## Overview

A **Free Pascal** command-line utility that launches programs with optional **administrator privilege elevation via Windows UAC**. Produces a single standalone `.exe` with zero runtime dependencies.

- **Language:** Free Pascal (ObjFPC mode, `{$H+}` — AnsiString in the system code page CP_ACP)
- **Target:** Windows 32/64-bit
- **Version:** 1.0 (Copyright 2026 grigorii.evseev@outlook.com)

## Architecture

### Source Files

| `run.pas` | Main program entry point; argument parsing, flow dispatch (`NormalStart`, `ElevatedStart`, `StartElevationProcess`, `RunTarget`) |
|---|---|
| `run.pas` | Main program entry point; argument parsing, flow dispatch (`NormalStart`, `ElevatedStart`, `StartElevationProcess`) |
| `includes.pas` | Unit with all Windows API declarations, type definitions, constants, and helper functions (MMF I/O, process creation, token queries) |

1. Parent parses flags → if `-a` is set and current token is not elevated, creates a named **Memory-Mapped File** (`Local\mmf_<pid>_<suffix>`) and a named **Event** (`Global\event_<pid>_<suffix>`, suffix = `UniqueSuffix()`)

1. Parent parses flags → if `-a` is set and current token is not elevated, creates a named **Memory-Mapped File** (`Local\mmf_<pid>`) and a named **Event** (`Global\event_<pid>`)
2. Command line string is written into the MMF
3. A copy of itself is launched via `ShellExecuteExW` with verb `runas` and marker `--elevated`
4. Parent waits on the Event (10s timeout); child reads the MMF, signals the Event, and executes the command

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
run.exe [-h | -m | -M | -n] [-a] COMMAND [PARAM1 "PARAM 2" ...]
```

| Flag | Window mode | Description |
|---|---|---|
| `-n` | `SW_NORMAL` | Normal window (default) |
| `-m` | `SW_MINIMIZE` | Minimized to tray |
| `-M` | `SW_MAXIMIZE` | Full-screen |
| `-h` | `SW_HIDE` | Hidden launch |
| `-a` | — | Elevate to Administrator via UAC |
| `-?` / `-H` | — | Print help and exit (code 102) |

Wrapper options are recognized only when an argument is exactly two characters long and starts with `-`; longer dashes (`--verbose`, `-1`) belong to the target program. The first non-option argument is the command, everything after it becomes parameters (each auto-quoted at launch/MMF write time). Flags without a command → exit code `116`.

### Exit Codes

Range **101–117**. Key codes: `101` = no parameters, `103` = unknown flag, `104` = process creation failed, `110` = ShellExecute failed, `116` = flags given but no command, `117` = UAC denial / elevated launch failure. See `README.md` for the full table.

## Testing

```bat
tests\run_tests.bat        { main test suite — 13 automated + 1 manual UAC }
tests\test_build.bat       { verifies build environment and compilation }
tests\test_parameters.bat  { parameter parsing, window modes, exit codes — 12 tests }
tests\test_elevation.bat   { UAC elevation; Test 5 auto-verifies code 117 on failed elevation }
```

Tests are batch scripts that call `run.exe` directly and check exit codes / output. Elevation tests prompt for UAC approval interactively (auto-skipped when stdin is redirected). Child-process results are verified with a bounded wait loop (`ping -n 2`) because the wrapper exits immediately after spawning.

## Coding Conventions

- **Free Pascal ObjFPC mode** with `{$H+}` (AnsiString, system code page CP_ACP — not UTF-8)
- Custom Windows API declarations in `includes.pas` rather than using standard RTL units — keeps the binary self-contained and minimal
- All external WinAPI declarations carry an explicit `stdcall` calling convention (required for correct i386-Win32 builds; without it `CreateProcessA` crashes with Runtime error 216)
- ANSI (`*A`) versions of WinAPI are used for MMF/Event naming and process creation; WideChar (`*W`) for `ShellExecuteExW`, fed by the explicit `AnsiToWide()` conversion (`MultiByteToWideChar(CP_ACP, ...)`)
- Error handling via `Halt(errorCode)` with custom codes 101–117 defined in `includes.pas`
- No external libraries or RTL dependencies beyond `System`
- Application state is kept in a single record `TApp` (`app` is the only global variable); all handles are initialised to zero

## Known Limitations (documented in README.md)

1. ~~UAC denial (`ShellExecuteEx` failure) is not reliably detected~~ — fixed: `SEE_MASK_NOCLOSEPROCESS` + `hProcess` check; a denied prompt or failed launch exits immediately with code 117 (message in `TXT_UAC_DENIED`)
2. ~~MMF name based on PID is predictable; no random suffix for collision protection~~ — fixed: names include a random `UniqueSuffix()` component (PID + 8 hex digits)
3. ~~Intermediate handle leaks possible if elevation fails mid-flow~~ — fixed with nested `try..finally` in `StartElevationProcess`
4. ~~ANSI WinAPI variants limit non-ASCII path support during elevation~~ — fixed: `ShellExec` converts CP_ACP strings via `AnsiToWide()`; remaining `*A` calls (CreateProcess, MMF/Event names) still rely on the system code page

## .gitignore

Excludes `*.exe`, `*.o`, `*.ppu`, `*.tmp`, `*.bak`, `Thumbs.db`, `*.log`.
