class_name SettingsMenu
extends Control

## Reusable settings presentation. SettingsManager owns all persistence and application.

signal back_requested

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var sensitivity_value: Label = %SensitivityValue

var _syncing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_options()
	SettingsManager.settings_changed.connect(_sync_from_settings)
	_sync_from_settings()


func focus_default() -> void:
	resolution_option.grab_focus()


func _populate_options() -> void:
	for item in SettingsManager.RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [item.x, item.y])
	window_mode_option.add_item("Оконный")
	window_mode_option.add_item("Без рамки")
	window_mode_option.add_item("Полноэкранный")


func _sync_from_settings() -> void:
	_syncing = true
	resolution_option.select(SettingsManager.RESOLUTIONS.find(SettingsManager.resolution))
	window_mode_option.select(SettingsManager.window_mode)
	vsync_check.button_pressed = SettingsManager.vsync_enabled
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	sensitivity_slider.value = SettingsManager.mouse_sensitivity / SettingsManager.DEFAULT_MOUSE_SENSITIVITY * 100.0
	_update_value_labels()
	_syncing = false


func _update_value_labels() -> void:
	master_value.text = "%d%%" % roundi(master_slider.value)
	music_value.text = "%d%%" % roundi(music_slider.value)
	sfx_value.text = "%d%%" % roundi(sfx_slider.value)
	sensitivity_value.text = "%.2f×" % (sensitivity_slider.value / 100.0)


func _on_resolution_option_item_selected(index: int) -> void:
	if not _syncing:
		SettingsManager.set_resolution(SettingsManager.RESOLUTIONS[index])


func _on_window_mode_option_item_selected(index: int) -> void:
	if not _syncing:
		SettingsManager.set_window_mode(index)


func _on_vsync_check_toggled(enabled: bool) -> void:
	if not _syncing:
		SettingsManager.set_vsync_enabled(enabled)


func _on_master_slider_value_changed(value: float) -> void:
	master_value.text = "%d%%" % roundi(value)
	if not _syncing:
		SettingsManager.set_master_volume(value / 100.0)


func _on_music_slider_value_changed(value: float) -> void:
	music_value.text = "%d%%" % roundi(value)
	if not _syncing:
		SettingsManager.set_music_volume(value / 100.0)


func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_value.text = "%d%%" % roundi(value)
	if not _syncing:
		SettingsManager.set_sfx_volume(value / 100.0)


func _on_sensitivity_slider_value_changed(value: float) -> void:
	sensitivity_value.text = "%.2f×" % (value / 100.0)
	if not _syncing:
		SettingsManager.set_mouse_sensitivity(
			SettingsManager.DEFAULT_MOUSE_SENSITIVITY * value / 100.0
		)


func _on_defaults_button_pressed() -> void:
	SettingsManager.reset_to_defaults()


func _on_back_button_pressed() -> void:
	back_requested.emit()
