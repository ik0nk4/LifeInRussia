extends Node

## Owns persistent user preferences and applies them to engine services.

signal settings_changed

enum GameWindowMode {
	WINDOWED,
	BORDERLESS,
	FULLSCREEN,
}

const SETTINGS_PATH := "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const DEFAULT_WINDOW_MODE := GameWindowMode.WINDOWED
const DEFAULT_VSYNC := true
const DEFAULT_MASTER_VOLUME := 0.85
const DEFAULT_MUSIC_VOLUME := 0.75
const DEFAULT_SFX_VOLUME := 0.85
const DEFAULT_MOUSE_SENSITIVITY := 0.002

var resolution := DEFAULT_RESOLUTION
var window_mode: int = DEFAULT_WINDOW_MODE
var vsync_enabled := DEFAULT_VSYNC
var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME
var mouse_sensitivity := DEFAULT_MOUSE_SENSITIVITY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_settings()
	apply_all()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	var width := int(config.get_value("video", "width", DEFAULT_RESOLUTION.x))
	var height := int(config.get_value("video", "height", DEFAULT_RESOLUTION.y))
	resolution = _validated_resolution(Vector2i(width, height))
	window_mode = clampi(
		int(config.get_value("video", "window_mode", DEFAULT_WINDOW_MODE)),
		GameWindowMode.WINDOWED,
		GameWindowMode.FULLSCREEN
	)
	vsync_enabled = bool(config.get_value("video", "vsync", DEFAULT_VSYNC))
	master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	mouse_sensitivity = clampf(
		float(config.get_value("controls", "mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY)),
		0.0005,
		0.005
	)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "width", resolution.x)
	config.set_value("video", "height", resolution.y)
	config.set_value("video", "window_mode", window_mode)
	config.set_value("video", "vsync", vsync_enabled)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Could not save settings to %s: error %s" % [SETTINGS_PATH, error])


func apply_all() -> void:
	_apply_video()
	_apply_audio()
	settings_changed.emit()


func set_resolution(value: Vector2i) -> void:
	resolution = _validated_resolution(value)
	_apply_and_save()


func set_window_mode(value: int) -> void:
	window_mode = clampi(value, GameWindowMode.WINDOWED, GameWindowMode.FULLSCREEN)
	_apply_and_save()


func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	_apply_and_save()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_and_save()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_and_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_and_save()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.005)
	save_settings()
	settings_changed.emit()


func reset_to_defaults() -> void:
	resolution = DEFAULT_RESOLUTION
	window_mode = DEFAULT_WINDOW_MODE
	vsync_enabled = DEFAULT_VSYNC
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	mouse_sensitivity = DEFAULT_MOUSE_SENSITIVITY
	_apply_and_save()


func _apply_and_save() -> void:
	apply_all()
	save_settings()


func _apply_video() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	match window_mode:
		GameWindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_apply_windowed_resolution()
		GameWindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_apply_windowed_resolution()
		GameWindowMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _apply_windowed_resolution() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var target_size := Vector2i(
		mini(resolution.x, screen_size.x),
		mini(resolution.y, screen_size.y)
	)
	DisplayServer.window_set_size(target_size)
	var screen_origin := DisplayServer.screen_get_position(screen)
	var available_space := screen_size - target_size
	var centered_offset := Vector2i(
		floori(available_space.x / 2.0),
		floori(available_space.y / 2.0)
	)
	DisplayServer.window_set_position(screen_origin + centered_offset)


func _apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_value))


func _validated_resolution(value: Vector2i) -> Vector2i:
	return value if value in RESOLUTIONS else DEFAULT_RESOLUTION
