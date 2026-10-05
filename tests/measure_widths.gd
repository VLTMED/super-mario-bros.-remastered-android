extends SceneTree
func _init() -> void:
	await process_frame
	var rtl = root.get_node("ArabicRTL")
	var main: Font = ThemeDB.get_project_theme().default_font
	var ar := rtl._composite_for(main) as Font
	var f := FileAccess.open("res://Resources/Locale/locale.csv", FileAccess.READ)
	var header := f.get_csv_line()
	var ien := header.find("en"); var iar := header.find("ar")
	var worse := []
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() <= iar or row[0] == "" or row[ien] == "": continue
		var en: String = row[ien]; var a: String = row[iar]
		if a == "": continue
		var ew := 0.0; var aw := 0.0
		for line in en.split("\n"): ew = maxf(ew, main.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
		for line in a.split("\n"): aw = maxf(aw, ar.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
		if aw > ew: worse.append([row[0], ew, aw])
	print("WIDER ", worse.size())
	worse.sort_custom(func(x, y): return (x[2] - x[1]) > (y[2] - y[1]))
	for w in worse.slice(0, 45): print("W|", w[0], "|en=", w[1], "|ar=", w[2], "|+", w[2] - w[1])
	quit()
