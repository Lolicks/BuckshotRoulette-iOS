# Анализ оригинала (REA MCP + ручная проверка)

## Артефакт

| Свойство | Значение |
|---|---|
| Файл | `Buckshot Roulette.exe` |
| SHA-256 | `4167fa2f604c01fc4f7b6b37071be220695729ca14bd5894fba1952520a7e3f4` |
| Формат | PE x86_64, встроенный Godot PCK |
| Движок | Godot 4.1.1-stable |
| PCK format | 2, `file_base=58282384`, `pack_start=57826816`, 3572 файла |
| Версия игры | v2.2.0.2 (`GlobalVariables.gd`) |

Evidence REA: `ev_e5fb49f6fd8a3181fb6cd6d28fcaabb380e540a7b89c4b6fb2d29e19fef6cdb9` (сводка), `ev_c59089a937e6d45baa4e22d7ab606c765fbd15a34ddef1ade42e302af962f78b` (инвентарь PCK).

## Состав PCK

- 195 GDScript (98 одиночных, 97 мультиплеерных) — исходный текст.
- 211 бинарных сцен (`.scn`), 74 ресурса (`.res`), 109 `.remap`.
- 986 текстур `.ctex` (874 S3TC + 1 BPTC + 112 lossless), 346 `.oggvorbisstr`, 8 `.sample`.
- 51 перевод (17 языков × 3 таблицы), 24 шрифта, 31 шейдер.

## Игровая логика (ключевое)

- Раунд: 3 раунда в батче, 3 батча. Патроны создаются в `ShellSpawner.gd`: `live` → `blank`, опционально shuffle; при `insertingInRandomOrder` — двойной shuffle.
- Урон: 1 (2 с ножовкой), ствол «отрастает» после каждого хода.
- Ход: пустой в себя → повтор; live → ход дилера; дилер при blank → повтор, иначе → игрок.
- ИИ (`DealerIntelligence.gd`): знание патрона (последний патрон, endless-дедукция, лупа), приоритет предметов: лупа → сигареты → лекарства → пиво → наручники → ножовка → телефон → инвертер. В сюжете目标 50/50, в endless — эвристика по числу live/blank.
- Предметы: handsaw, magnifying glass, beer, cigarettes, handcuffs, expired medicine, burner phone, adrenaline, inverter.
- Endless: HP 2–4, патронов 2–8 (`live = max(1, total/2)`), предметов 2–5.
- Сохранения: `user://buckshotroulette_*_12.shell`.

## Меню и UI

7 экранов (`MenuManager.Show`): main, sub options, credits, audio video, language, controller, rebind controls. 17 языков. Настройки: громкость, fullscreen, геймпад, цветовая слепота, музыка, greyscale death, ремап клавиш.

Аудио: 5 шин (Master + reverb/limiter, music + lowpass, music_secondary, interactions, music_resolve). 3 музыкальных трека с second-loop вариантами.

## Что изменено в порте

1. Добавлен `steam_stub.gd` (autoload `Steam`) — Steamworks полностью отключён.
2. `MenuManager.StartMultiplayer()` → no-op (онлайн-режим убран).
3. Текстуры S3TC → ETC2 (875 файлов) для iOS.
4. PCK собирается напрямую (`tools/build_pck.py`), т.к. экспорт Godot из распакованного проекта не видит часть импортированных ресурсов без исходных PNG.
5. Добавлен iOS export preset и CI workflow для сборки IPA.
