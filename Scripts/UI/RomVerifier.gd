class_name ROMVerifier
extends Node

const VALID_HASHES := [
	"6a54024d5abe423b53338c9b418e0c2ffd86fed529556348e52ffca6f9b53b1a",
	"c9b34443c0414f3b91ef496d8cfee9fdd72405d673985afa11fb56732c96152b"
]

var android_picker: Object = null
var file_picker_ready := false
var desktop_file_dialog: FileDialog = null

func haptic_feedback() -> void:
	Input.vibrate_handheld(3, 0.5)

func _ready() -> void:
	Global.get_node("GameHUD").hide()
	OnScreenControls.should_show = false
	await get_tree().physics_frame
	_initialize_file_picker()

func _initialize_file_picker() -> void:
	# The bundled Android export plugin is named AndroidFilePicker. Keep the
	# legacy name as a compatibility fallback for older exported builds.
	for singleton_name in [&"AndroidFilePicker", &"GodotFilePicker"]:
		if Engine.has_singleton(singleton_name):
			android_picker = Engine.get_singleton(singleton_name)
			break
	if android_picker != null and android_picker.has_signal(&"file_picked"):
		if not android_picker.file_picked.is_connected(on_file_selected):
			android_picker.file_picked.connect(on_file_selected)
		file_picker_ready = true
		return
	# A desktop fallback makes the verifier testable outside Android and avoids
	# a null singleton crash when the export plugin is unavailable.
	desktop_file_dialog = FileDialog.new()
	desktop_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	desktop_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	desktop_file_dialog.filters = PackedStringArray(["*.nes, *.nez, *.fds, *.qd, *.unf, *.unif, *.nsf, *.nsfe ; ROM files"])
	desktop_file_dialog.file_selected.connect(_on_desktop_file_selected)
	add_child(desktop_file_dialog)

func _on_desktop_file_selected(path: String) -> void:
	handle_rom(path)

func on_screen_tapped() -> void:
	haptic_feedback()
	if file_picker_ready:
		android_picker.openFilePicker("*/*")
	elif desktop_file_dialog != null:
		desktop_file_dialog.popup_centered_ratio(0.8)

func on_file_selected(temp_path: String, _mime_type: String) -> void:
	handle_rom(temp_path)
	if temp_path.begins_with("/tmp/") or temp_path.contains("/cache/"):
		DirAccess.remove_absolute(temp_path)

func handle_rom(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		error()
		return false
	if path.get_extension() in ["zip", "7z", "rar", "tar", "gz", "gzip", "bz2"]:
		zip_error()
		return false
	if not is_valid_rom(path):
		if path.get_extension() in ["nes", "nez", "fds", "qd", "unf", "unif", "nsf", "nsfe"]:
			error()
		else:
			extension_error()
		return false
	Global.rom_path = Global.ROM_PATH
	copy_rom(path)
	verified()
	return true

func copy_rom(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		return
	DirAccess.copy_absolute(file_path, Global.ROM_PATH)

static func get_hash(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var file_bytes := file.get_buffer(40976)
	if file_bytes.size() < 16:
		return ""
	var data := file_bytes.slice(16)
	return Marshalls.raw_to_base64(data).sha256_text()

static func is_valid_rom(rom_path := "") -> bool:
	return not rom_path.is_empty() and FileAccess.file_exists(rom_path) and get_hash(rom_path) in VALID_HASHES

func error() -> void:
	%Error.show()
	%ZipError.hide()
	%ExtensionError.hide()
	$ErrorSFX.play()

func zip_error() -> void:
	%ZipError.show()
	%Error.hide()
	%ExtensionError.hide()
	$ErrorSFX.play()

func extension_error() -> void:
	%ExtensionError.show()
	%Error.hide()
	%ZipError.hide()
	$ErrorSFX.play()

func verified() -> void:
	$BGM.queue_free()
	%DefaultText.queue_free()
	%SuccessMSG.show()
	$SuccessSFX.play()
	await get_tree().create_timer(3, false).timeout
	var target_scene := "res://Scenes/Levels/TitleScreen.tscn"
	if not Global.rom_assets_exist:
		target_scene = "res://Scenes/Levels/RomResourceGenerator.tscn"
	Global.transition_to_scene(target_scene)

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()
	OnScreenControls.should_show = true
