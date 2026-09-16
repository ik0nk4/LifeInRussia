extends Control

## Controls the main menu flow without owning any visual styling.
## Assign [member new_game_scene_path] when the polling station scene is available.

@export_file("*.tscn") var new_game_scene_path := "res://scenes/locations/polling_station.tscn"

@onready var new_game_button: Button = %NewGameButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	new_game_button.grab_focus()


func _on_new_game_button_pressed() -> void:
	if not ResourceLoader.exists(new_game_scene_path, "PackedScene"):
		_show_status("Сцена избирательного участка пока не готова.")
		push_warning("Main menu could not find the new game scene: %s" % new_game_scene_path)
		return

	var error := get_tree().change_scene_to_file(new_game_scene_path)
	if error != OK:
		_show_status("Не удалось начать новую игру.")
		push_error("Failed to change to the new game scene (%s): error %s" % [new_game_scene_path, error])


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _show_status(message: String) -> void:
	status_label.text = message
	status_label.show()
