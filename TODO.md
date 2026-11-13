# TODO — RunAs Utility

## 🔴 Критические

- [x] **Исправить проверку возврата `ShellExecuteExW`** (`includes.pas`, `ShellExec`)  
  Сейчас: `result := (GetLastError() = 0)` — ненадёжно.  
  Нужно: `result := ShellExecuteExW(@sei);` — проверять фактическое возвращаемое значение функции.  
  ✅ Исправлено: `result := ShellExecuteExW(@sei);`

- [x] **Добавить очистку хендлов при частичном сбое** (`run.pas`, `StartElevationProcess`)  
  При ошибке после `CreateFileMapping` хендл MMF не закрывается; аналогично для Event.  
  Обернуть блок создания ресурсов в `try..finally` с закрытием всех ненулевых хендлов.  
  ✅ Исправлено: два вложенных `try..finally` — внутренний закрывает `eventHandle`, внешний — `mmfHandle`.

- [x] **Экранировать путь команды при записи в MMF** (`run.pas`, `StartElevationProcess` + `includes.pas`, `WriteMMF`)  
  Путь с пробелами без кавычек ломает парсинг `CreateProcess(nil, lpCommandLine, ...)` в `ElevatedStart`.  
  Либо оборачивать `command` в `"..."` при записи, либо хранить команду и параметры раздельно (с разделителем) в MMF.  
  ✅ Исправлено: строка `commandLine := Quoted(command) + ' ' + parameters;` используется и для прямого запуска, и для записи в MMF.

- [x] **Кодировка при элевации** (`includes.pas`, `ShellExec`)  
  При `{$H+}` строки — AnsiString в системной кодовой странице (CP_ACP), а не UTF-8. `UTF8Decode()` ломал кириллические пути именно в элевации (`ShellExecuteExW`).  
  ✅ Исправлено: добавлена функция `AnsiToWide` на базе `MultiByteToWideChar(CP_ACP, ...)`; `ShellExec` использует её для команды и параметров.

- [x] **Парсинг флагов runas путался с флагами целевой программы** (`run.pas`, `NormalStart`)  
  Аргументы вида `--verbose` или `-1` после команды расценивались как флаги обёртки.  
  ✅ Исправлено: опции обёртки распознаются только при длине ровно 2 символа и начале с `-`; неизвестный флаг до команды → `ERROR_UNDEFINED_PARAMETERS`, после команды → параметр цели.

- [x] **Отдельный код ошибки «нет команды»** (`includes.pas`, `run.pas`)  
  Запуск только из флагов (например, `run.exe -n`) завершался как «нет параметров» (101).  
  ✅ Исправлено: добавлен `ERROR_NO_COMMAND = 116`.

- [x] **Явные stdcall для WinAPI в i386-сборке** (`includes.pas`)  
  Без явного описания конвенции вызова 32-битная сборка падала (Runtime error 216) на `CreateProcessA` и других внешних функциях.  
  ✅ Исправлено: всем внешним объявлениям добавлен явный `stdcall`; сборка `build.bat` для i386-Win32 работает.

## 🟡 Значимые

- [x] **Добавить `SEE_MASK_NOCLOSEPROCESS` и проверку `hProcess`** (`includes.pas`, `ShellExec`)  
  Без этого невозможно отличить успешный запуск от отказа UAC пользователем.  
  ✅ Исправлено: в fMask добавлен `SEE_MASK_NOCLOSEPROCESS`; если `hProcess = 0`, считаем неудачей (хендл закрывается после проверки).
- [x] **Улучшить сообщение при отказе UAC** (`run.pas`, `StartElevationProcess`)  
  Сейчас родитель ждёт 10 сек и падает с `ERROR_ON_WAITING_EVENT` (109).  
  Добавить отдельный сигнал или проверку `hProcess` для вывода понятного сообщения.  
  ✅ Исправлено: новый код `ERROR_UAC_DENIED = 117` + сообщение `TXT_UAC_DENIED`; при неудаче ShellExecuteEx выходим сразу, не дожидаясь события.

- [ ] **Добавить случайную компоненту в имя MMF / Event** (`run.pas`, константы)  
  PID перерабатывается Windows — добавить `Random()` суффикс для защиты от коллизий.

- [ ] **Устранить дублирование логики запуска команды** (`run.pas`)  
  `RunCommand(...)` вызывается в 3 местах (`NormalStart`, `StartElevationProcess`, `ElevatedStart`).  
  Вынести общую логику в отдельную процедуру/функцию.

## 🟢 Улучшения

- [ ] **Добавить `IntToStr(Value: DWORD)`** (`includes.pas`)  
  `GetCurrentProcessId` возвращает `DWORD`; текущих перегрузок (`Longint`, `Int64`, `QWord`) нет точного совпадения.

- [ ] **Заменить глобальные переменные на record/структуру** (`run.pas`)  
  `mode`, `elevation`, `command`, `parameters`, `mmfName`, `mmfHandle`, `eventName`, `eventHandle` — всё в global scope.

- [ ] **Добавить `FileExists(command)` перед запуском** (`includes.pas`, `RunCommand`)  
  Дать понятное сообщение, если файл команды не существует, вместо generic `ERROR_CREATE_PROCESS`.
