extends Node

## Coordinates the one-way polling-station introduction sequence.

enum IntroState {
	AWAITING_BALLOT,
	BALLOT_COMPLETED,
	FINISHED,
}

const PARTIES_PATH := "res://data/intro/parties.json"

@onready var player: PlayerController = $"../Player"
@onready var voting_booth: InteractionArea = $"../VotingBooth/InteractionArea"
@onready var ballot_box: InteractionArea = $"../BallotBox/InteractionArea"
@onready var ui: IntroUi = $"../UI"

var selected_party_id := ""
var state := IntroState.AWAITING_BALLOT
var _parties: Array = []


func _ready() -> void:
	_parties = _load_parties()
	voting_booth.interaction_requested.connect(_on_voting_booth_interacted)
	ballot_box.interaction_requested.connect(_on_ballot_box_interacted)
	player.interaction_hint_changed.connect(ui.set_interaction_hint)
	ui.ballot_confirmed.connect(_on_ballot_confirmed)
	ballot_box.interaction_hint = "Сначала заполните бюллетень."


func _on_voting_booth_interacted(_area: InteractionArea) -> void:
	if state != IntroState.AWAITING_BALLOT:
		return

	if _parties.is_empty():
		push_error("Polling station intro has no valid parties to display.")
		return

	player.set_movement_enabled(false)
	ui.show_ballot(_parties)


func _on_ballot_confirmed(party_id: String) -> void:
	if state != IntroState.AWAITING_BALLOT:
		return

	selected_party_id = party_id
	state = IntroState.BALLOT_COMPLETED
	voting_booth.interaction_hint = "Бюллетень уже заполнен."
	ballot_box.interaction_hint = "Опустить бюллетень (E)"
	ui.hide_ballot()
	player.set_movement_enabled(true)
	player.refresh_interaction_hint()


func _on_ballot_box_interacted(_area: InteractionArea) -> void:
	if state != IntroState.BALLOT_COMPLETED:
		return

	state = IntroState.FINISHED
	ballot_box.interaction_hint = "Голос принят. Можно выйти на улицу."
	player.refresh_interaction_hint()


func _load_parties() -> Array:
	var file := FileAccess.open(PARTIES_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open polling parties data: %s" % PARTIES_PATH)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Polling parties data must contain a JSON array: %s" % PARTIES_PATH)
		return []

	return parsed
