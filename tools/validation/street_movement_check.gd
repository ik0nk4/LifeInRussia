extends SceneTree
## Exercise the real player controller, door input, pause, and collision.

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _ticks(count: int) -> void:
	for frame in count:
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await _ticks(2)
	Input.action_release(action)


func _run() -> void:
	change_scene_to_file("res://scenes/locations/polling_station.tscn")
	await scene_changed
	var location := current_scene
	var player: CharacterBody3D = location.get_node("Player")
	var transition: Node = location.get_node("LocationTransition")
	var interior: Node3D = location.get_node("Environment")
	var street: Node3D = location.get_node("Street")
	_check(physics_interpolation, "Physics interpolation is disabled")
	await _ticks(3)
	var start := player.global_position
	Input.action_press("move_forward")
	await _ticks(30)
	Input.action_release("move_forward")
	await _ticks(3)
	_check(player.global_position.z < start.z - 1.5, "Indoor movement catches on the floor")
	_check(absf(player.global_position.y - start.y) < 0.01, "Indoor movement changes height unexpectedly")
	var view_start: float = player.camera.global_rotation.y
	var mouse := InputEventMouseMotion.new()
	mouse.screen_relative = Vector2(80, 0)
	player._unhandled_input(mouse)
	_check(absf(player.camera.global_rotation.y - view_start) > 0.1, "Mouse look did not update immediately")
	# Use the actual E action and raycast rather than calling the transition.
	var door_position := interior.to_global(Vector3(4.25, 0, 4.15))
	player.teleport_to(Transform3D(Basis(Vector3.UP, PI), door_position))
	await _ticks(3)
	_check(player.interaction_ray.get_collider() == interior.get_node("ExitInteraction"), "Exit is not reachable by the gameplay ray")
	await _press("interact")
	await transition.transition_finished
	await _ticks(3)
	_check(transition.is_outside and player.movement_enabled, "Exit did not restore input")
	_check(player.camera.global_position.distance_to(player.global_position + Vector3(0, 1.6, 0)) < 0.01,
		"Teleport left a camera interpolation streak")
	# Forward takes the player across the zebra crossing; scenery must not block it.
	player.teleport_to(Transform3D(Basis(Vector3.UP, PI), street.to_global(Vector3(5, 0, -3))))
	Input.action_press("move_forward")
	await _ticks(150)
	Input.action_release("move_forward")
	await _ticks(3)
	_check(player.position.z > 5.5, "The pavement/crossing route is blocked")
	for sweep in [
		[Vector3(19.8, 0, 4), Vector3(1, 0, 0)],
		[Vector3(-19.8, 0, 4), Vector3(-1, 0, 0)],
		[Vector3(17, 0, -4.4), Vector3(0, 0, -1)],
		[Vector3(-17, 0, -4.4), Vector3(0, 0, -1)],
		[Vector3(0, 0, 11.5), Vector3(0, 0, 1)],
	]:
		_check(player.test_move(Transform3D(Basis.IDENTITY, street.to_global(sweep[0])), sweep[1]),
			"Missing courtyard boundary at %s" % sweep[0])
	var pause: Node = location.get_node("PauseMenu")
	pause._open_pause()
	var pause_position := player.global_position
	await process_frame
	_check(paused and not player.movement_enabled, "Outdoor pause failed")
	pause._close_pause()
	_check(not paused and player.movement_enabled and player.global_position == pause_position, "Unpausing changed the player position or controls")
	player.teleport_to(Transform3D(Basis.IDENTITY, street.to_global(Vector3(6, 0, -3.95))))
	await _ticks(3)
	_check(player.interaction_ray.get_collider() == street.get_node("EntranceInteraction"), "Return door is not reachable")
	await _press("interact")
	await transition.transition_finished
	await _ticks(3)
	_check(not transition.is_outside and is_zero_approx(transition.curtain.color.a), "Return left a fade or the wrong location active")
	_check(player.global_position.distance_to(interior.get_node("ReturnSpawn").global_position) < 0.01,
		"Return spawn does not follow the interior offset")
	print("STREET MOVEMENT CHECK: %s" % ("PASS" if _failures == 0 else "%s failures" % _failures))
	quit(0 if _failures == 0 else 1)
