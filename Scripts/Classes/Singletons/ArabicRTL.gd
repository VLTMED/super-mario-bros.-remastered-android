extends Node
## Arabic support that keeps the game's own look and layout.
##
## - Arabic letters are drawn with a pixel Arabic font (Solar 6, Arabic-only subset). Everything else (Latin, digits,
##   spaces, punctuation, symbols) still comes from the game's own font, so it looks exactly like the original.
## - Solar is drawn 1:1 (one font pixel = one screen pixel) and has the same 16 px line box as Font.fnt: no extra pixel.
## - The UI is mirrored (RTL), except zones that must look like the original: the on-screen touch controls and the
##   top HUD bar (MARIO / coins / WORLD / TIME).

const ARABIC_LOCALE := "ar"
const ARABIC_FONT_PATH := "res://Resources/Fonts/Solar6-Arabic-UI16.ttf"
## Font.fnt line box is 16 px high and glyph bottoms sit 5 px above the line bottom; Solar is shifted to match.
const GLYPH_BOTTOM_GAP := 5
const GAME_FONT_SIZE := 16.0
const META_ORIGINAL := &"_arabic_rtl_original"

var _arabic_base: FontFile
var _composites: Dictionary = {}  # original font instance id -> composite FontVariation
var _is_arabic := false

func _enter_tree() -> void:
	_arabic_base = FontFile.new()
	if _arabic_base.load_dynamic_font(ARABIC_FONT_PATH) != OK:
		push_error("Cannot load Arabic font: " + ARABIC_FONT_PATH)
		return
	# Pixel-crisp rendering: no smoothing, no hinting, no sub-pixel placement, no system fallback.
	_arabic_base.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_arabic_base.hinting = TextServer.HINTING_NONE
	_arabic_base.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_arabic_base.allow_system_fallback = false
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

## Composite = Arabic pixel font first, the game's original font as fallback for everything Arabic does not cover.
func _composite_for(original: Font) -> Font:
	if original == null:
		return null
	var id := original.get_instance_id()
	if _composites.has(id):
		return _composites[id]
	var composite := FontVariation.new()
	composite.base_font = _arabic_base
	# Same line box as Font.fnt (ascent 16, descent 0) and the same visual baseline as its glyphs.
	composite.spacing_top = GLYPH_BOTTOM_GAP
	composite.spacing_bottom = -GLYPH_BOTTOM_GAP
	composite.baseline_offset = -GLYPH_BOTTOM_GAP / GAME_FONT_SIZE
	composite.fallbacks = [original]
	_composites[id] = composite
	return composite

func _is_ltr_only(node: Node) -> bool:
	var current := node
	while current != null:
		var script := current.get_script() as Script
		if script != null:
			var path := script.resource_path
			# On-screen touch controls and the top HUD bar must look exactly like the original.
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
		if _is_ltr_only(control):
			control.layout_direction = Control.LAYOUT_DIRECTION_LTR if _is_arabic else Control.LAYOUT_DIRECTION_INHERITED
			# Text such as "*00" or "1-1" must keep its original left-to-right order.
			_set_text_direction(control, TextServer.DIRECTION_LTR if _is_arabic else TextServer.DIRECTION_INHERITED)
			_restore_font(control)
		else:
			control.layout_direction = Control.LAYOUT_DIRECTION_RTL if _is_arabic else Control.LAYOUT_DIRECTION_INHERITED
			_set_text_direction(control, TextServer.DIRECTION_INHERITED)
			_apply_font(control)
	for child in root.get_children():
		_apply_to_tree(child)

func _set_text_direction(control: Control, direction: int) -> void:
	if control is Label or control is Button or control is LineEdit or control is TextEdit or control is RichTextLabel:
		control.set(&"text_direction", direction)

func _has_text_font(control: Control) -> bool:
	return control is Label or control is Button or control is LineEdit or control is TextEdit or control is RichTextLabel

func _apply_font(control: Control) -> void:
	if not _has_text_font(control):
		return
	if not _is_arabic:
		_restore_font(control)
		return
	if not control.has_meta(META_ORIGINAL):
		control.set_meta(META_ORIGINAL, {
			"font": control.get_theme_font(&"font") if control.has_theme_font_override(&"font") else null,
			"was_override": control.has_theme_font_override(&"font"),
		})
	var original: Dictionary = control.get_meta(META_ORIGINAL)
	var source: Font = original["font"] if original["was_override"] else control.get_theme_font(&"font")
	if source != null:
		control.add_theme_font_override(&"font", _composite_for(source))

func _restore_font(control: Control) -> void:
	if not control.has_meta(META_ORIGINAL):
		return
	var original: Dictionary = control.get_meta(META_ORIGINAL)
	if original["was_override"] and original["font"] != null:
		control.add_theme_font_override(&"font", original["font"])
	else:
		control.remove_theme_font_override(&"font")
	control.remove_meta(META_ORIGINAL)
