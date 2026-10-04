extends Node
## Arabic localization runtime support: RTL layout, Arabic-capable font, and live locale updates.
const ARABIC_LOCALE := "ar"
const ARABIC_FONT := preload("res://Resources/Fonts/NotoKufiArabic-Regular.ttf")
var _is_arabic := false

func _enter_tree() -> void:
    get_tree().node_added.connect(_on_node_added)
    call_deferred("apply_locale", TranslationServer.get_locale())

func _on_node_added(node: Node) -> void:
    if _is_arabic and node is Control:
        call_deferred("_apply_to_tree", node)

func apply_locale(locale: String) -> void:
    var arabic := locale == ARABIC_LOCALE or locale.begins_with(ARABIC_LOCALE + "-")
    _is_arabic = arabic
    if get_tree().root != null:
        _apply_to_tree(get_tree().root)

func _apply_to_tree(root: Node) -> void:
    if not is_instance_valid(root):
        return
    if root is Control:
        var control := root as Control
        control.layout_direction = Control.LAYOUT_DIRECTION_RTL if _is_arabic else Control.LAYOUT_DIRECTION_INHERITED
        if _is_arabic and (control is Label or control is Button or control is LineEdit or control is TextEdit or control is SpinBox or control is OptionButton):
            control.add_theme_font_override("font", ARABIC_FONT)
        elif not _is_arabic:
            control.remove_theme_font_override("font")
    for child in root.get_children():
        _apply_to_tree(child)
