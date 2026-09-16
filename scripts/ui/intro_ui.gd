class_name IntroUi
extends CanvasLayer

## Displays contextual hints and owns ballot input and completion presentation.

@onready var interaction_hint: Label = %InteractionHint
@onready var ballot_panel: PanelContainer = %BallotPanel
@onready var party_list: VBoxContainer = %PartyList
@onready var confirm_button: Button = %ConfirmButton
@onready var completion_panel: PanelContainer = %CompletionPanel

var _selected_party_id := ""
var _party_group := ButtonGroup.new()

signal ballot_confirmed(party_id: String)


func _ready() -> void:
	ballot_panel.hide()
	completion_panel.hide()
	confirm_button.disabled = true


func set_interaction_hint(hint: String) -> void:
	interaction_hint.text = hint
	interaction_hint.visible = not hint.is_empty()


func show_ballot(parties: Array) -> void:
	_selected_party_id = ""
	confirm_button.disabled = true
	for child in party_list.get_children():
		child.queue_free()

	for party in parties:
		if not party is Dictionary:
			continue

		var party_id := str(party.get("id", ""))
		var party_name := str(party.get("name", party_id))
		if party_id.is_empty():
			continue

		var party_button := Button.new()
		party_button.text = party_name
		party_button.toggle_mode = true
		party_button.button_group = _party_group
		party_button.pressed.connect(_select_party.bind(party_id))
		party_list.add_child(party_button)

	ballot_panel.show()
	if party_list.get_child_count() > 0:
		(party_list.get_child(0) as Control).grab_focus()


func hide_ballot() -> void:
	ballot_panel.hide()


func show_completion() -> void:
	set_interaction_hint("")
	completion_panel.show()


func _select_party(party_id: String) -> void:
	_selected_party_id = party_id
	confirm_button.disabled = false


func _on_confirm_button_pressed() -> void:
	if not _selected_party_id.is_empty():
		ballot_confirmed.emit(_selected_party_id)
