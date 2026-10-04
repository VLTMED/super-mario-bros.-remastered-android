extends SceneTree

func _init() -> void:
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
