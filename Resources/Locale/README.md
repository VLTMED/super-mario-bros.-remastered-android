# Localization

`locale.csv` is the single source of truth for in-game text. Each language is a
column identified by its Godot locale code. The Arabic column uses `ar` and is
kept beside the existing translations so contributors can review keys and
context in one place.

## Adding or reviewing Arabic text

1. Add or update the key in `locale.csv`.
2. Keep the `description` column intact; it is translation context.
3. Put the Modern Standard Arabic value in the `ar` column.
4. Run the localization check workflow (or `godot --headless --editor --quit`).
5. Godot regenerates the `.translation` resources from the CSV on import.

Arabic UI behavior is implemented in `Scripts/Classes/Singletons/ArabicRTL.gd`:
when `ar` is selected, the UI is mirrored (RTL) and Arabic letters are drawn with the bundled pixel font
`Resources/Fonts/Solar6-Arabic-UI16.ttf` (see the NOTICE file next to it). The game's own font stays the
fallback for Latin text, digits and symbols, so every line keeps the original 16 px line height.
The on-screen touch controls and the top HUD bar (MARIO / WORLD / TIME) always stay LTR like the original.
On the very first launch the game picks the device language when it is supported.
