class_name PauseMenu
extends CanvasLayer

## Pauses gameplay and hosts the shared settings screen.

@export_file("*.tscn") var main_menu_scene_path := "res://scenes/ui/main_menu.tscn"
@export_node_path("PlayerController") var player_path: NodePath

@onready var pause_content: Control = %PauseContent
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var continue_button: Button = %ContinueButton

var _player: PlayerController
var _was_movement_enabled := true
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node_or_null(player_path) as PlayerController
	settings_menu.back_requested.connect(_show_pause_content)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return

	get_viewport().set_input_as_handled()
	if not visible:
		_open_pause()
	elif settings_menu.visible:
		_show_pause_content()
	else:
		_close_pause()


func _open_pause() -> void:
	_was_movement_enabled = _player.movement_enabled if is_instance_valid(_player) else true
	_previous_mouse_mode = Input.mouse_mode
	if is_instance_valid(_player):
		_player.set_movement_enabled(false)
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	settings_menu.hide()
	pause_content.show()
	show()
	continue_button.grab_focus()


func _close_pause() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(_player):
		_player.set_movement_enabled(_was_movement_enabled)
	Input.set_mouse_mode(_previous_mouse_mode)


func _show_pause_content() -> void:
	settings_menu.hide()
	pause_content.show()
	continue_button.grab_focus()


func _on_continue_button_pressed() -> void:
	_close_pause()


func _on_settings_button_pressed() -> void:
	pause_content.hide()
	settings_menu.show()
	settings_menu.focus_default()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var error := get_tree().change_scene_to_file(main_menu_scene_path)
	if error != OK:
		push_error("Failed to return to main menu: error %s" % error)


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
