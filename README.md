# RunAs Utility

A command-line utility that launches programs with **elevated (administrator) privileges** on Windows via UAC. Written in **Free Pascal**, it compiles to a self-contained `.exe` with no dependencies.

---

## Contents

- [Features](#features)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Examples](#examples)
- [How it works](#how-it-works)
- [Exit codes](#exit-codes)
- [Testing](#testing)

---

## Features

| Feature | Description |
|---|---|
| **Privilege elevation** | Launch any command with administrator rights via UAC (`-a`) |
| **Window modes** | Normal, minimized, maximized, hidden (`-n`, `-m`, `-M`, `-h`) |
| **IPC via MMF** | The command line is passed between processes through a memory-mapped file |
| **Synchronization** | A Windows event coordinates the parent and child processes |
| **Portability** | A single `.exe` file, no dependencies |

---

## Quick start

### Build

```bat
build.bat
```

Or manually:

```bat
fpc -O3 -CX -XX -Xs run.pas
strip run.exe
```

> **Requirements:** the Free Pascal Compiler (`fpc`); `strip` is optional (reduces binary size).
>
> **Bitness:** `build.bat` invokes `fpc` from PATH, so the result matches the target platform of the installed FPC (i386-Win32 or x64-Win64). For an x64 binary you need a 64-bit compiler in PATH.

---

## Usage

```
run.exe [-h | -m | -M | -n] [-w] [-v] [-a] COMMAND [PARAM1 "PARAM 2" ...]
```

### Options

| Flag | Window mode | Description |
|---|---|---|
| `-n` / `--normal` | `SW_NORMAL` | Normal window **(default)** |
| `-m` / `--minimize` | `SW_MINIMIZE` | Minimized to the tray |
| `-M` / `--maximize` | `SW_MAXIMIZE` | Maximized across the screen |
| `-h` / `--hide` | `SW_HIDE` | Hidden launch |
| `-w` / `--nowindow` | — | No console window at all (`CREATE_NO_WINDOW`; together with `-a` the elevated copy also gets `SEE_MASK_NO_CONSOLE`) |
| `-v` / `--verbose` | — | Verbose output of intermediate steps to stderr (debugging) |
| `-a` / `--admin` | — | Launch with administrator rights |
| `-?` / `--help` | — | Print help |

> Long forms (`--…`) are recognized **only before the command**; after the command any dash-prefixed argument is treated as a parameter of the target program.

### Arguments

| Argument | Description |
|---|---|
| `COMMAND` | Path to an executable file or command |
| `PARAM1 PARAM2 ...` | Parameters passed to the command (strings containing spaces can be quoted) |

> **Flag recognition rule:** wrapper options (`-h`, `-m`, `-M`, `-n`, `-w`, `-v`, `-a`, `-?`) are recognized only when an argument is exactly two characters long and starts with `-`. Anything longer (`--verbose`, `--elevated`, `-1`) is treated as a parameter of the target program. The first non-flag argument becomes the command; all subsequent arguments become parameters (each one is automatically quoted at launch and in the MMF).
>
> If flags are given but no command is (`run.exe -n`), the exit code is `116`.

---

## Examples

```bat
:: Normal launch
run.exe notepad.exe

:: Launch with administrator rights
run.exe -a cmd.exe

:: Hidden elevated launch
run.exe -h -a taskkill /F /IM example.exe

:: Minimized elevated launch with parameters
run.exe -m -a powershell.exe "Get-Process"

:: Maximized window
run.exe -M notepad.exe "C:\file.txt"
```

---

## How it works

### Without elevation (no `-a`)

1. Command-line arguments are parsed
2. The command is launched directly via `CreateProcessW`

### With elevation (`-a`)

1. **The parent process** checks its current privileges
2. If they are sufficient, the command is launched directly
3. Otherwise:
   - A **named MMF** (memory-mapped file) with a unique name (PID + random suffix) is created
   - The final command line is written into the MMF
   - A **named event** in an unsignaled state is created
   - A **copy of itself** is launched via `ShellExecuteExW` with the `runas` verb and the `--elevated` marker; a failed launch or UAC denial exits immediately with code 117
   - The parent waits on both the event and the child process handle (timeout 10 s): if the elevated copy dies before signaling, it fails fast with code 119
4. **The child process** (with admin rights):
   - Opens and reads the MMF
   - Signals the event (the parent continues)
   - Executes the command via `CreateProcessW`
   - Releases resources

---

## Exit codes

| Code | Constant | Description |
|---|---|---|
| `101` | `ERROR_NO_PARAMETERS` | No parameters were passed |
| `102` | `ERROR_REQUEST_HELP` | Help was requested |
| `103` | `ERROR_UNDEFINED_PARAMETERS` | Unknown flag before the command |
| `104` | `ERROR_CREATE_PROCESS` | Failed to create the process |
| `105` | `ERROR_CANT_OPEN_SECURITY_TOKEN` | Failed to open the process token |
| `106` | `ERROR_CANT_WRITE_MMF` | Failed to write into the MMF |
| `107` | `ERROR_CREATE_MMF` | Failed to create the MMF |
| `108` | `ERROR_CREATE_EVENT` | Failed to create the event |
| `109` | `ERROR_ON_WAITING_EVENT` | Timeout while waiting for the event (child still alive) |
| `110` | `ERROR_SHELL_EXECUTE` | ShellExecute error |
| `111` | `ERROR_READ_MMF` | Failed to read the MMF |
| `112` | `ERROR_OPEN_MMF` | Failed to open the MMF |
| `113` | `ERROR_MAP_MMF` | Failed to map the MMF |
| `114` | `ERROR_OPEN_EVENT` | Failed to open the event |
| `115` | `ERROR_SET_EVENT` | Failed to signal the event |
| `116` | `ERROR_NO_COMMAND` | Only flags were passed, no command |
| `117` | `ERROR_UAC_DENIED` | UAC prompt was denied or the elevated launch failed to start |
| `118` | `ERROR_COMMAND_NOT_FOUND` | The executable does not exist at the given path (checked via `GetFileAttributesW`; bare names without separators are resolved through PATH by CreateProcess itself) |
| `119` | `ERROR_ELEVATED_CHILD_FAILED` | The elevated process terminated before reading the command from the MMF |

---

## Testing

The `tests/` directory contains automated batch suites:

- `run_tests.bat` — main suite (launch modes, quoting, error codes)
- `test_parameters.bat` — option parsing, `-w`, verbose mode, long aliases
- `test_build.bat` — verifies the build script works
- `test_elevation.bat` — elevation scenarios (the UAC-dependent tests are skipped when no operator is present)

Run them from a command prompt:

```bat
tests\run_tests.bat
```
