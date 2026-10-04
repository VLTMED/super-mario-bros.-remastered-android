extends Node
## Arabic localization runtime support: RTL layout, OpenType-shaped pixel Arabic font (Solar 6) and live locale updates.
##
## - UI text switches to the Solar 6 pixel font (and back) without destroying the game's own font overrides.
## - The on-screen touch controls (d-pad / A / B / Run / Start) are never mirrored: they stay LTR.

const ARABIC_LOCALE := "ar"
## Solar 6 is drawn on a 7-unit pixel grid. 14px is the closest 2x pixel scale to
## the game's 16px bitmap UI while keeping glyph edges on a stable integer grid.
const FONT_GRID := 7
const DEFAULT_FONT_SIZE := 14
const META_ORIGINAL := &"_arabic_rtl_original"
## Nodes under a CanvasLayer running this script are never mirrored.
const LTR_ONLY_SCRIPT := "OnScreenControls.gd"

var _font: FontFile = preload("res://Resources/Fonts/Solar6VF.ttf")
var _is_arabic := false

func _enter_tree() -> void:
	# Pixel-crisp rendering: no smoothing, no hinting, no sub-pixel placement.
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	get_tree().node_added.connect(_on_node_added)
	call_deferred("apply_locale", TranslationServer.get_locale())

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
		if current is CanvasLayer:
			var script := current.get_script() as Script
			if script != null and script.resource_path.ends_with(LTR_ONLY_SCRIPT):
				return true
		current = current.get_parent()
	return false

func _apply_to_tree(root: Node) -> void:
	if not is_instance_valid(root):
		return
	var ltr_only := _is_ltr_only(root)
	if root is Control:
		var control := root as Control
		if ltr_only:
			control.layout_direction = Control.LAYOUT_DIRECTION_LTR if _is_arabic else Control.LAYOUT_DIRECTION_INHERITED
		else:
			control.layout_direction = Control.LAYOUT_DIRECTION_RTL if _is_arabic else Control.LAYOUT_DIRECTION_INHERITED
			_apply_font(control)
	for child in root.get_children():
		_apply_to_tree(child)

func _uses_font(control: Control) -> bool:
	return control is Label or control is Button or control is LineEdit or control is TextEdit or control is SpinBox or control is RichTextLabel

func _apply_font(control: Control) -> void:
	if not _uses_font(control):
		return
	if _is_arabic:
		if not control.has_meta(META_ORIGINAL):
			# Remember what the control had before (null = nothing, i.e. it used the theme).
			control.set_meta(META_ORIGINAL, {
				"font": control.get_theme_font(&"font") if control.has_theme_font_override(&"font") else null,
				"size": control.get_theme_font_size(&"font_size") if control.has_theme_font_size_override(&"font_size") else 0,
			})
		var original: Dictionary = control.get_meta(META_ORIGINAL)
		control.add_theme_font_override(&"font", _font)
		control.add_theme_font_size_override(&"font_size", _snap_size(int(original["size"])))
	elif control.has_meta(META_ORIGINAL):
		var original: Dictionary = control.get_meta(META_ORIGINAL)
		if original["font"] != null:
			control.add_theme_font_override(&"font", original["font"])
		else:
			control.remove_theme_font_override(&"font")
		if int(original["size"]) > 0:
			control.add_theme_font_size_override(&"font_size", int(original["size"]))
		else:
			control.remove_theme_font_size_override(&"font_size")
		control.remove_meta(META_ORIGINAL)

func _snap_size(original_size: int) -> int:
	if original_size <= 0:
		return DEFAULT_FONT_SIZE
	return maxi(FONT_GRID, roundi(original_size / float(FONT_GRID)) * FONT_GRID)
