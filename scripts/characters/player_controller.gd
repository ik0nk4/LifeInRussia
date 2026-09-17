class_name PlayerController
extends CharacterBody3D

## First-person movement and interaction for the introductory location.

@export var move_speed := 3.5
@export var mouse_sensitivity := 0.002

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var movement_enabled := true
var _current_interaction: InteractionArea
var _last_hint := ""
var _view_yaw := 0.0
var _view_pitch := 0.0
var _eye_offset := Vector3(0, 1.6, 0)

signal interaction_hint_changed(hint: String)


func _ready() -> void:
	_eye_offset = camera.position
	_view_yaw = global_rotation.y
	camera.top_level = true
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_sync_camera(false)
	mouse_sensitivity = SettingsManager.mouse_sensitivity
	SettingsManager.settings_changed.connect(_on_settings_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled:
		return

	if event is InputEventMouseMotion:
		_view_yaw -= event.screen_relative.x * mouse_sensitivity
		_view_pitch = clampf(_view_pitch - event.screen_relative.y * mouse_sensitivity,
			deg_to_rad(-80.0), deg_to_rad(80.0))
		_sync_camera(true)


func _process(_delta: float) -> void:
	_sync_camera(true)


func _sync_camera(interpolated: bool) -> void:
	var body_transform := get_global_transform_interpolated() if interpolated else global_transform
	camera.global_position = body_transform.origin + _eye_offset
	camera.global_rotation = Vector3(_view_pitch, _view_yaw, 0.0)


func teleport_to(destination: Transform3D) -> void:
	global_transform = destination
	velocity = Vector3.ZERO
	_view_yaw = destination.basis.get_euler().y
	_view_pitch = 0.0
	reset_physics_interpolation()
	_sync_camera(false)
	interaction_ray.force_raycast_update()
	refresh_interaction_hint()


func _physics_process(_delta: float) -> void:
	_update_interaction()

	if not movement_enabled:
		velocity = Vector3.ZERO
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction := (Basis(Vector3.UP, _view_yaw) * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	velocity.y = 0.0
	move_and_slide()

	if Input.is_action_just_pressed("interact") and is_instance_valid(_current_interaction):
		_current_interaction.request_interaction()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE)
	if not enabled:
		_current_interaction = null
		_set_hint("")


func refresh_interaction_hint() -> void:
	_last_hint = "__refresh_interaction_hint__"
	_update_interaction()


func _update_interaction() -> void:
	if not movement_enabled:
		return

	var collider := interaction_ray.get_collider()
	_current_interaction = collider as InteractionArea
	if is_instance_valid(_current_interaction):
		_set_hint(_current_interaction.get_interaction_hint())
	else:
		_set_hint("")


func _set_hint(hint: String) -> void:
	if hint == _last_hint:
		return

	_last_hint = hint
	interaction_hint_changed.emit(hint)


func _on_settings_changed() -> void:
	mouse_sensitivity = SettingsManager.mouse_sensitivity
