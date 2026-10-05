extends SceneTree
# Usage: godot --path . --script tests/shot_settings.gd -- <locale> <scene> <out.png>
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var locale: String = args[0] if args.size() > 0 else "en"
	var scene_path: String = args[1] if args.size() > 1 else "res://Scenes/Prefabs/UI/SettingsMenu.tscn"
	var out: String = args[2] if args.size() > 2 else "/home/claude/shots/out.png"
	await process_frame
	await process_frame
	TranslationServer.set_locale(locale)
	if root.has_node("ArabicRTL"):
		root.get_node("ArabicRTL").apply_locale(locale)
	var packed: PackedScene = load(scene_path)
	var inst := packed.instantiate()
	root.add_child(inst)
	if inst.has_method("open"):
		inst.open()
	var cat := int(args[3]) if args.size() > 3 else 0
	if cat > 0 and "category_index" in inst:
		inst.category_index = cat
		inst.current_container = inst.containers[cat]
		for c in inst.containers:
			c.visible = c == inst.current_container
	for i in 8:
		await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(out)
	print("SHOT ", out, " size=", root.get_texture().get_image().get_size())
	quit()
