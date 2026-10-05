extends Node
## Arabic localization that preserves the game's original 16px layout and font sizes.
## Arabic uses the supplied full OpenType pixel font; the original HUD and special score fonts stay intact.

const ARABIC_LOCALE := "ar"
const ARABIC_FONT_PATH := "res://Resources/Fonts/SMB-Remastered-ArabicPixel16-Regular.ttf"
const META_ORIGINAL := &"_arabic_rtl_original"

var _font := FontFile.new()
var _is_arabic := false

func _enter_tree() -> void:
	var font_error := _font.load_dynamic_font(ARABIC_FONT_PATH)
	if font_error != OK:
		push_error("Cannot load Arabic OpenType font: " + ARABIC_FONT_PATH)
		return
	# Match the game's pixel renderer. No font-size or control-size changes are made here.
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	get_tree().node_added.connect(_on_node_added)
	call_deferred("apply_locale", TranslationServer.get_locale())

func is_arabic() -> bool:
	return _is_arabic

func _on_node_added(node: Node) -> void:
	if _is_arabic and node is Control:
		call_deferred("_apply_to_tree", node)

func apply_locale(locale: String) -> void:
	_is_arabic = locale == ARABIC_LOCALE or locale.begins_with(ARABIC_LOCALE + "-")
	if get_tree().root != null:
		_apply_to_tree(get_tree().root)

func _is_ltr_only(node: Node) -> bool:
	var current := node
	while current != null:
		var script := current.get_script() as Script
		if script != null:
			var path := script.resource_path
			# The original HUD geometry is fixed and its labels remain English/LTR.
			if path.ends_with("OnScreenControls.gd") or path.ends_with("GameHUD.gd"):
				return true
		if current.name == &"VersionLabel":
			return true
		current = current.get_parent()
	return false

func _apply_to_tree(root: Node) -> void:
	if not is_instance_valid(root):
		return
	if root is Control:
		var control := root as Control
		if _is_arabic:
			_remember_original(control)
			if _is_ltr_only(control):
				control.layout_direction = Control.LAYOUT_DIRECTION_LTR
				_set_text_direction(control, TextServer.DIRECTION_LTR)
				_restore_font(control)
			else:
				# Do not mirror every Control. Mirroring Panel/Margin/VBox/Scroll containers
				# changes their minimum-size negotiation and was the source of the oversized
				# Arabic settings frame. Only text and horizontal flow need RTL.
				control.layout_direction = Control.LAYOUT_DIRECTION_RTL if _needs_rtl_flow(control) else Control.LAYOUT_DIRECTION_INHERITED
				_set_text_direction(control, TextServer.DIRECTION_INHERITED)
				_apply_font(control)
		else:
			_restore_original(control)
	for child in root.get_children():
		_apply_to_tree(child)

func _is_text_control(control: Control) -> bool:
	return control is Label or control is Button or control is LineEdit or control is TextEdit or control is SpinBox or control is RichTextLabel

func _needs_rtl_flow(control: Control) -> bool:
	return _is_text_control(control) or control is HBoxContainer or control is GridContainer

func _set_text_direction(control: Control, direction: int) -> void:
	if _is_text_control(control):
		control.set(&"text_direction", direction)

func _remember_original(control: Control) -> void:
	if control.has_meta(META_ORIGINAL):
		return
	var had_font_override := control.has_theme_font_override(&"font")
	var original_font: Font = control.get_theme_font(&"font") if had_font_override else null
	var font_class := original_font.get_class() if original_font != null else ""
	var font_path := original_font.resource_path if original_font != null else ""
	control.set_meta(META_ORIGINAL, {
		"layout_direction": control.layout_direction,
		"text_direction": control.get(&"text_direction") if _is_text_control(control) else TextServer.DIRECTION_INHERITED,
		"had_font_override": had_font_override,
		"font": original_font,
		"font_class": font_class,
		"font_path": font_path,
	})

func _is_main_font(original: Dictionary) -> bool:
	if not original["had_font_override"]:
		return true
	var font_class: String = original["font_class"]
	var font_path: String = original["font_path"]
	# Preserve ScoreFont, SystemFont and any other deliberately special font override.
	if font_class == "SystemFont":
		return false
	if font_path.contains("ScoreFont"):
		return false
	return font_path.is_empty() or font_path.contains("FontMain") or font_path.ends_with("Font.fnt")

func _apply_font(control: Control) -> void:
	if not _is_text_control(control):
		return
	var original: Dictionary = control.get_meta(META_ORIGINAL)
	if not _is_main_font(original):
		return
	# The supplied font already contains Arabic, Latin, digits and symbols.
	# Do not change font_size: the original theme size and every fixed panel remain untouched.
	control.add_theme_font_override(&"font", _font)

func _restore_font(control: Control) -> void:
	if not control.has_meta(META_ORIGINAL):
		return
	var original: Dictionary = control.get_meta(META_ORIGINAL)
	if original["had_font_override"] and original["font"] != null:
		control.add_theme_font_override(&"font", original["font"])
	else:
		control.remove_theme_font_override(&"font")

func _restore_original(control: Control) -> void:
	if not control.has_meta(META_ORIGINAL):
		return
	var original: Dictionary = control.get_meta(META_ORIGINAL)
	control.layout_direction = original["layout_direction"]
	if _is_text_control(control):
		control.set(&"text_direction", original["text_direction"])
	_restore_font(control)
	control.remove_meta(META_ORIGINAL)
