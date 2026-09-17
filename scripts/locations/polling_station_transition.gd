extends Node
## Keeps both spaces in one session so leaving never resets the ballot.

const STREET_ENVIRONMENT = preload("res://scenes/locations/polling_station_street_environment.tres")

signal transition_finished

@onready var player: PlayerController = $"../Player"
@onready var interior: Node3D = $"../Environment"
@onready var street: Node3D = $"../Street"
@onready var exit_area: InteractionArea = $"../Environment/ExitInteraction"
@onready var entrance_area: InteractionArea = $"../Street/EntranceInteraction"
@onready var indoor_spawn: Marker3D = $"../Environment/ReturnSpawn"
@onready var outdoor_spawn: Marker3D = $"../Street/ExitSpawn"
@onready var curtain: ColorRect = $"../LocationFade/Curtain"

var is_outside := false
var _transition_pending := false


func _ready() -> void:
	exit_area.interaction_requested.connect(_on_exit_requested)
	entrance_area.interaction_requested.connect(_on_entrance_requested)
	street.hide()
	curtain.hide()
	player.teleport_to(indoor_spawn.global_transform)


func _on_exit_requested(_area: InteractionArea) -> void:
	_request_transition(true)


func _on_entrance_requested(_area: InteractionArea) -> void:
	_request_transition(false)


func _request_transition(outside: bool) -> void:
	if _transition_pending or outside == is_outside or not player.movement_enabled:
		return
	_transition_pending = true
	player.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Interactions happen during physics; defer teleporting until it finishes.
	call_deferred("_fade_transition", outside)


func _fade_transition(outside: bool) -> void:
	curtain.show()
	var fade_out := create_tween()
	fade_out.tween_property(curtain, "color:a", 1.0, 0.12)
	await fade_out.finished
	_apply_transition(outside)
	var fade_in := create_tween()
	fade_in.tween_property(curtain, "color:a", 0.0, 0.18)
	await fade_in.finished
	curtain.hide()
	player.set_movement_enabled(true)
	_transition_pending = false
	transition_finished.emit()


func _apply_transition(outside: bool) -> void:
	is_outside = outside
	interior.visible = not outside
	street.visible = outside
	var spawn := outdoor_spawn if outside else indoor_spawn
	player.teleport_to(spawn.global_transform)
	player.camera.environment = STREET_ENVIRONMENT if outside else null
	player.interaction_ray.force_raycast_update()
	player.refresh_interaction_hint()
