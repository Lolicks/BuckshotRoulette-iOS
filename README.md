# Buckshot Roulette — офлайн-порт для iOS

Полная реконструкция игры **Buckshot Roulette v2.2.0.2** (оригинальный движок Godot 4.1.1) без онлайн-режима.

## Что внутри

- `game/` — восстановленный проект Godot 4.1.1: все GDScript-исходники, сцены, текстуры, звуки, музыка, шрифты и 17 локализаций, извлечённые из встроенного PCK оригинального `Buckshot Roulette.exe`.
- Текстуры перекодированы в **ETC2** — формат, который понимают iOS-устройства (в оригинале был только S3TC/DXT).
- `steam_stub.gd` — офлайн-заглушка Steamworks. Онлайн-меню отключено в `scripts/MenuManager.gd`.
- **Сенсорное управление для iOS** (`scripts/TouchControls.gd`): тапы превращаются в клики (плюс прямой обработчик в `MouseRaycast.gd`/`InteractionManager.gd` с защитой от двойных срабатываний), экранные кнопки **EXIT** (удержание 2 сек / пропуск интро), **SKIP** и **◀ ▶** для CRT-терминала. На iOS скрывается ремап клавиш.
- `tools/build_pck.py` — сборка полного PCK напрямую из ассетов (экспорт Godot из «вынутого» проекта теряет часть ресурсов).
- `.github/workflows/build-ios.yml` — сборка IPA через GitHub Actions (Ubuntu → Xcode-проект, macOS → IPA).

Игра 1:1 повторяет оригинал: меню, интро, звуки, музыка, игровая логика, предметы, ИИ дилера, бесконечный режим, настройки и сохранения.

## Сборка IPA

1. Запустить workflow `Build iOS IPA` в GitHub Actions (вручную или пушем в `main`).
2. После завершения скачать артефакт `BuckshotRoulette-IPA`.

IPA подписан без Apple Developer ID (`CODE_SIGNING_ALLOWED=NO`), поэтому для установки нужны инструменты вроде AltStore/Sideloadly или переподписка своим сертификатом.

Готовый артефакт также лежит локально: `output/BuckshotRoulette.ipa` (~650 МБ). Внутри — `Payload/BuckshotRoulette.app` и PCK на 5328 файлов (включая `TouchControls.gd` и ETC2-текстуры).

Workflow использует `macos-latest`: он instantaneously находит раннер, в отличие от перегруженного `macos-13`. Перед сборкой CI патчит сгенерированный Godot 4.1 `project.pbxproj` (экранирует `ES LATAM`), иначе Xcode 26 не может открыть проект.

## Локальная проверка

```powershell
# запуск проекта в Godot 4.1.1
Godot_v4.1.1-stable_win64_console.exe --headless --path game --quit

# сборка PCK
python tools/build_pck.py game build\FullGame.pck

# проверка PCK
Godot_v4.1.1-stable_win64_console.exe --headless --main-pack build\FullGame.pck --quit-after 5
```

## Онлайн (свой сервер, без Steam)

- Сервер: `server/server.js` (Node.js + `ws`), API совместимо со Steam-слоем игры через `scripts/SteamNet.gd`.
- Адрес по умолчанию: `ws://buckshot-129-146-71-78.nip.io/ws` (nginx → локальный `:9090`, порт 80 наружу). Сайты на сервере не затронуты — добавлен отдельный vhost.
- Игроки видят публичный список комнат в лобби, входят по клику, никаких логинов и паролей.
- Хост авторитетен: сервер только ретранслирует пакеты, игровая логика и проверка запросов остаются на хосте.
- Сервер запущен как systemd-сервис `buckshot-net` на VPS.

ДляiOS в Info.plist добавляется `NSAllowsArbitraryLoads=true`, иначе ATS блокирует `ws://`.

## Технические детали

Анализ исходного бинарника performed с помощью REA MCP: PE x86_64, встроенный Godot PCK (format 2, engine 4.1.1), 3572 записи, `file_base=58282384`, `pack_start=57826816`. Движок, версия и составconfirmed evidence `ev_e5fb49f6fd8a3181fb6cd6d28fcaabb380e540a7b89c4b6fb2d29e19fef6cdb9`.

Игровая логика (раунды, патроны, урон, предметы, ИИ дилера) разобрана из `game/scripts/RoundManager.gd`, `ShellSpawner.gd`, `DealerIntelligence.gd`, `ItemManager.gd` и др.
