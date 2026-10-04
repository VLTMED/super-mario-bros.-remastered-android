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
when `ar` is selected, controls use RTL layout and the bundled Solar 6 pixel Arabic font
(`Resources/Fonts/Solar6VF.ttf`, free to use). The on-screen touch controls always stay LTR.
Switching back to another language restores the original theme font and layout.
