# Buckshot Roulette — офлайн-порт для iOS

Полная реконструкция игры **Buckshot Roulette v2.2.0.2** (оригинальный движок Godot 4.1.1) без онлайн-режима.

## Что внутри

- `game/` — восстановленный проект Godot 4.1.1: все GDScript-исходники, сцены, текстуры, звуки, музыка, шрифты и 17 локализаций, извлечённые из встроенного PCK оригинального `Buckshot Roulette.exe`.
- Текстуры перекодированы в **ETC2** — формат, который понимают iOS-устройства (в оригинале был только S3TC/DXT).
- `steam_stub.gd` — офлайн-заглушка Steamworks. Онлайн-меню отключено в `scripts/MenuManager.gd`.
- `tools/build_pck.py` — сборка полного PCK напрямую из ассетов (экспорт Godot из «вынутого» проекта теряет часть ресурсов).
- `.github/workflows/build-ios.yml` — сборка IPA через GitHub Actions (Ubuntu → Xcode-проект, macOS → IPA).

Игра 1:1 повторяет оригинал: меню, интро, звуки, музыка, игровая логика, предметы, ИИ дилера, бесконечный режим, настройки и сохранения.

## Сборка IPA

1. Запустить workflow `Build iOS IPA` в GitHub Actions (вручную или пушем в `main`).
2. После завершения скачать артефакт `BuckshotRoulette-IPA`.

IPA подписан без Apple Developer ID (`CODE_SIGNING_ALLOWED=NO`), поэтому для установки нужны инструменты вроде AltStore/Sideloadly или переподписка своим сертификатом.

## Локальная проверка

```powershell
# запуск проекта в Godot 4.1.1
Godot_v4.1.1-stable_win64_console.exe --headless --path game --quit

# сборка PCK
python tools/build_pck.py game build\FullGame.pck

# проверка PCK
Godot_v4.1.1-stable_win64_console.exe --headless --main-pack build\FullGame.pck --quit-after 5
```

## Технические детали

Анализ исходного бинарника performed с помощью REA MCP: PE x86_64, встроенный Godot PCK (format 2, engine 4.1.1), 3572 записи, `file_base=58282384`, `pack_start=57826816`. Движок, версия и составconfirmed evidence `ev_e5fb49f6fd8a3181fb6cd6d28fcaabb380e540a7b89c4b6fb2d29e19fef6cdb9`.

Игровая логика (раунды, патроны, урон, предметы, ИИ дилера) разобрана из `game/scripts/RoundManager.gd`, `ShellSpawner.gd`, `DealerIntelligence.gd`, `ItemManager.gd` и др.
