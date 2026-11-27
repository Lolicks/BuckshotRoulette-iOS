# Buckshot Roulette — кроссплатформенный офлайн/онлайн порт

Полная реконструкция **Buckshot Roulette v2.2.0.2** (Godot 4.1.1) для **iPhone** и **Windows ПК**, с собственным онлайном без Steam.

## Возможности

- Одиночная игра 1:1: меню, интро, звуки, музыка, 17 языков, игровая логика, 9 предметов, ИИ дилера, бесконечный режим.
- Онлайн: публичный список комнат, никаких логинов/паролей, хост авторитетен. PC и iPhone играют вместе.
- Сенсорное управление на iOS: тапы, long-press → free-look, кнопки **MENU / EXIT / SKIP / ◀ ▶**.
- Внутриигровое меню: **Esc** (ПК) или **MENU** (айфон, всегда видна в игре, слой 500) → Resume / Settings / Exit to Main Menu.
- Быстрый старт: лёгкая сцена `loading.tscn` показывает «Loading…» сразу, а тяжёлое меню грузится в фоне через `load_threaded_request`. Задержка splashreduced до 0.5 с, логирование выключено.
- PCK собирается из полного дерева ассетов: ~5330 файлов, ~1.1 ГБ. Удаление мультиплеерных моделей/звуков откачено — `mp_lobby.scn` ссылается на них напрямую, без них лобби показывало чёрный экран.
- Настройки графики прямо в игре: Low / Medium / High (масштаб 3D, MSAA, тени, FPS), громкость, музыка, colorblind, greyscale death. Сохраняются в `user://buckshotroulette_graphics.cfg`.

## Готовые бинарники

Локально в `output/`:

| Файл | Для чего |
|---|---|
| `BuckshotRoulette.ipa` | iPhone (unsigned — AltStore/Sideloadly) |
| `BuckshotRoulette.exe` + `BuckshotRoulette.pck` | Windows (должны лежать рядом) |
| `START_PC.bat` | запуск ПК-версии |
| `vulkan-1.dll`, `vulkan_lvp.dll`, `lvp_icd.x86_64.json` | софтверный Vulkan (lavapipe) |
| `INSTALL_OPENGL.bat` / `UNINSTALL_OPENGL.bat` / `START_OPENGL.bat` | системная Mesa OpenGL для старых GPU (обратимо) |

### Важно про старый ПК (Intel HD 3000)

Такой GPU поддерживает только OpenGL 3.1 / D3D10.1, а Godot 4 требует OpenGL 3.3. Проверено:
- `lavapipe` не даёт расширения `VK_KHR_surface` → окно создать нельзя;
- локальный `opengl32.dll` игнорируется, потому что это KnownDLL.

Поэтому для старого ПК предлагается временная замена системных DLL на Mesa через `INSTALL_OPENGL.bat` (от админа), запуск через `START_OPENGL.bat` и восстановление через `UNINSTALL_OPENGL.bat`. Если и это не поможет — используй любой другой ПК с видеокартой: онлайн кроссплатформенный.

## Онлайн-сервер

- Код: `server/server.js` (Node.js + `ws`).
- Адрес клиента: `ws://buckshot-129-146-71-78.nip.io/ws` (nginx → `127.0.0.1:9090`, отдельный vhost на 80-м порту; существующие сайты не изменены).
- systemd-сервис: `buckshot-net` на VPS.
- Идентификаторы выдаёт сервер, имена — никнеймы. Пакеты GZIP-сжимаются и передаются в JSON envelope.
- Хост проверяет запросы через `MP_PacketVerification.gd`, сервер только ретранслирует.
- При выходе хоста из матча комната расформировывается (полная миграция состояния не реализована).

Подробности: `server/README.md`.

## Сборка

GitHub Actions: `.github/workflows/build-ios.yml`, один run строит **оба** артефакта:
1. Ubuntu: Godot 4.1.1 + export templates → Xcode-проект и полный PCK (5330 файлов) + Windows EXE на `gl_compatibility`.
2. macOS: `xcodebuild` → unsigned IPA. В Info.plist добавляется ATS-exception, в pbxproj экранируется `ES LATAM` для Xcode 26.

## Исходное исследование

REA MCP: PE x86_64, встроенный Godot PCK format 2, engine 4.1.1, 3572 файла, `file_base=58282384`. Подробности — `docs/ANALYSIS.md`.
