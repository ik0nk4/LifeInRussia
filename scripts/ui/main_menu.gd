extends Control

## Controls the main menu flow and swaps to the shared settings screen.

@export_file("*.tscn") var new_game_scene_path := "res://scenes/locations/polling_station.tscn"

@onready var menu_content: Control = %MenuContent
@onready var new_game_button: Button = %NewGameButton
@onready var status_label: Label = %StatusLabel
@onready var settings_menu: SettingsMenu = %SettingsMenu


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	settings_menu.back_requested.connect(_show_main_menu)
	settings_menu.hide()
	new_game_button.grab_focus()
	_play_entrance_animation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_menu.visible:
		get_viewport().set_input_as_handled()
		_show_main_menu()


func _on_new_game_button_pressed() -> void:
	if not ResourceLoader.exists(new_game_scene_path, "PackedScene"):
		_show_status("Сцена избирательного участка пока не готова.")
		push_warning("Main menu could not find the new game scene: %s" % new_game_scene_path)
		return

	var error := get_tree().change_scene_to_file(new_game_scene_path)
	if error != OK:
		_show_status("Не удалось начать новую игру.")
		push_error("Failed to change to the new game scene (%s): error %s" % [new_game_scene_path, error])


func _on_settings_button_pressed() -> void:
	menu_content.hide()
	settings_menu.show()
	settings_menu.focus_default()


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _show_main_menu() -> void:
	settings_menu.hide()
	menu_content.show()
	new_game_button.grab_focus()


func _show_status(message: String) -> void:
	status_label.text = message
	status_label.show()


func _play_entrance_animation() -> void:
	menu_content.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(menu_content, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
