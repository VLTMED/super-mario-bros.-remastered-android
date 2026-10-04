extends SceneTree

func _init() -> void:
    var arabic_script := FileAccess.open("res://Scripts/Classes/Singletons/ArabicRTL.gd", FileAccess.READ)
    if arabic_script == null:
        push_error("ArabicRTL.gd is missing")
        quit(1)
        return
    var rtl_source := arabic_script.get_as_text()
    for required in ["Solar6VF.ttf", "FONT_ANTIALIASING_NONE", "HINTING_NONE", "SUBPIXEL_POSITIONING_DISABLED", "DEFAULT_FONT_SIZE := 14"]:
        if rtl_source.find(required) < 0:
            push_error("Arabic pixel/OpenType setting is missing: " + required)
            quit(1)
            return
    var arabic_font := FontFile.new()
    if arabic_font.load_dynamic_font("res://Resources/Fonts/Solar6VF.ttf") != OK:
        push_error("Arabic OpenType font cannot be loaded")
        quit(1)
        return
    var file := FileAccess.open("res://Resources/Locale/locale.csv", FileAccess.READ)
    if file == null:
        push_error("Cannot open locale.csv")
        quit(1)
        return
    var header: PackedStringArray = file.get_csv_line()
    var arabic_index := header.find("ar")
    if arabic_index < 0:
        push_error("Arabic locale column is missing")
        quit(1)
        return
    var keys := {}
    var count := 0
    while not file.eof_reached():
        var row: PackedStringArray = file.get_csv_line()
        if row.is_empty() or row[0].is_empty():
            continue
        if keys.has(row[0]):
            push_error("Duplicate localization key: " + row[0])
            quit(1)
            return
        keys[row[0]] = true
        if row.size() <= arabic_index or row[arabic_index].strip_edges().is_empty():
            push_error("Missing Arabic value: " + row[0])
            quit(1)
            return
        count += 1
    print("Validated %d localization keys with Arabic coverage" % count)
    quit(0)
