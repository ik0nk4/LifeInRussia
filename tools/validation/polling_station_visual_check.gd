extends SceneTree
## Run: godot --headless --path . --script tools/validation/polling_station_visual_check.gd
## Optional rendered views: omit --headless, append -- --capture-dir=<absolute directory>.

var _failures := 0
var _player: CharacterBody3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _walk(target: Vector3) -> void:
	if not current_scene.get_node("LocationTransition").is_outside:
		target.y = current_scene.get_node("Environment").position.y
	for step in 400:
		var motion := target - _player.position
		if motion.length() < 0.015:
			return
		_player.move_and_collide(motion.limit_length(0.05))
		_player._sync_camera(false)
		await physics_frame
	_check(false, "Route blocked before %s; player at %s" % [target, _player.position])


func _aim(area: Area3D) -> void:
	_camera.look_at(area.global_position)
	var ray: RayCast3D = _camera.get_node("InteractionRay")
	ray.force_raycast_update()
	_check(ray.get_collider() == area, "Interaction ray missed %s" % area.name)
	_player.refresh_interaction_hint()


func _run() -> void:
	var previous_msaa := root.msaa_3d
	var previous_taa := root.use_taa
	var previous_atlas := root.positional_shadow_atlas_size
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await scene_changed
	current_scene.get_node("%NewGameButton").pressed.emit()
	await scene_changed
	var location := current_scene
	_check(location.name == "PollingStationIntro", "New Game did not load polling station")
	_player = location.get_node("Player")
	_camera = _player.get_node("Camera3D")
	_player.set_physics_process(false)
	_player.set_process(false)
	var controller: Node = location.get_node("IntroController")
	var booth: Area3D = location.get_node("VotingBooth/InteractionArea")
	var urn: Area3D = location.get_node("BallotBox/InteractionArea")
	var ui: CanvasLayer = location.get_node("UI")
	var environment: Node3D = location.get_node("Environment")
	var transition: Node = location.get_node("LocationTransition")
	var exit_area: Area3D = environment.get_node("ExitInteraction")
	var entrance: Area3D = location.get_node("Street/EntranceInteraction")
	_check(environment.get_node("Visual").get_child_count() > 100, "Imported Blender environment is missing")
	_check(environment.get_node("Collision").get_child_count() >= 20, "Simplified environment collision is incomplete")
	_check(not location.get_node("VotingBooth").has_node("Visual"), "Legacy booth visual is still active")
	_check(not location.get_node("BallotBox").has_node("Visual"), "Legacy ballot-box visual is still active")
	await physics_frame
	# Leave and return before voting, then repeat with a completed ballot.
	await _walk(Vector3(4.25, 0, 4.15))
	_aim(exit_area)
	exit_area.request_interaction()
	await transition.transition_finished
	await physics_frame
	_check(transition.is_outside and _player.movement_enabled, "Could not leave before voting")
	await _walk(entrance.global_position + Vector3(0, -1.6, 0.85))
	_aim(entrance)
	entrance.request_interaction()
	await transition.transition_finished
	await physics_frame
	_check(not transition.is_outside and controller.state == 0, "Return reset or advanced the intro")
	urn.request_interaction()
	_check(controller.state == 0, "Urn accepted an empty ballot")
	await _walk(Vector3(4.25, 0, 2.6))
	await _walk(Vector3(1.0, 0, 1.8))
	await _walk(Vector3(1.0, 0, -2.55))
	await _walk(Vector3(2.45, 0, -2.7))
	await _walk(Vector3(2.45, 0, -3.25))
	_aim(booth)
	booth.request_interaction()
	_check(ui.ballot_panel.visible and not _player.movement_enabled, "Ballot did not open")
	_check(ui.confirm_button.disabled, "Empty ballot can be confirmed")
	var party_button: Button = ui.party_list.get_child(0)
	party_button.pressed.emit()
	ui.confirm_button.pressed.emit()
	_check(controller.state == 1 and not controller.selected_party_id.is_empty(), "Party selection failed")
	_check(_player.movement_enabled and not ui.ballot_panel.visible, "Movement was not restored")
	var selected_party: String = controller.selected_party_id
	transition._on_exit_requested(exit_area)
	await transition.transition_finished
	await physics_frame
	transition._on_entrance_requested(entrance)
	await transition.transition_finished
	await physics_frame
	_check(controller.state == 1 and controller.selected_party_id == selected_party, "Leaving lost the completed ballot")
	# Resume the urn route from the return spawn.
	await _walk(Vector3(4.25, 0, 2.6))
	await _walk(Vector3(1.0, 0, 1.8))
	await _walk(Vector3(1.0, 0, -2.55))
	await _walk(Vector3(2.45, 0, -2.55))
	await _walk(Vector3(1.2, 0, -1.8))
	await _walk(Vector3(1.2, 0, 0.5))
	await _walk(Vector3(2.55, 0, 0.5))
	_aim(urn)
	# Sweep the actual player capsule against the critical rigid objects.
	for sweep in [
		[Vector3(2.55, 0, 0.7), Vector3(0, 0, -1.5)],
		[Vector3(-4.65, 0, -1.8), Vector3(0, 0, -1.5)],
		[Vector3(2.45, 0, -3.25), Vector3(0, 0, -1.2)],
		[Vector3(4.65, 0, -3.25), Vector3(0, 0, -1.2)],
		[Vector3(6.3, 0, 2.2), Vector3(1.1, 0, 0)],
		[Vector3(4.25, 0, 3.75), Vector3(0, 0, 1.5)],
		[Vector3(-2.15, 0, 2.8), Vector3(0, 0, 1.3)],
	]:
		var start := Transform3D(Basis.IDENTITY, sweep[0] + Vector3(0, environment.position.y, 0))
		_check(_player.test_move(start, sweep[1]), "Missing obstacle collision at %s" % sweep[0])
	urn.request_interaction()
	_check(controller.state == 2 and not ui.completion_panel.visible, "Vote did not complete without a blocking panel")
	_check(_player.movement_enabled, "Cannot walk to the exit after voting")
	await _walk(Vector3(1.2, 0, 0.5))
	await _walk(Vector3(1.2, 0, 2.6))
	await _walk(Vector3(4.25, 0, 2.6))
	await _walk(Vector3(4.25, 0, 4.15))
	_aim(exit_area)
	exit_area.request_interaction()
	await transition.transition_finished
	await physics_frame
	_check(transition.is_outside and _camera.environment != null, "Street transition failed after voting")
	await _walk(entrance.global_position + Vector3(0, -1.6, 0.85))
	_aim(entrance)
	entrance.request_interaction()
	await transition.transition_finished
	await physics_frame
	_check(not transition.is_outside and _camera.environment == null, "Interior environment did not return")
	_check(controller.state == 2 and controller.selected_party_id == selected_party, "Return lost the submitted vote")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			await _capture(location, argument.trim_prefix("--capture-dir="))
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await scene_changed
	_check(root.msaa_3d == previous_msaa and root.use_taa == previous_taa, "Anti-aliasing settings leaked out of location")
	_check(root.positional_shadow_atlas_size == previous_atlas, "Shadow atlas setting leaked out of location")
	print("POLLING VISUAL CHECK: %s" % ("PASS" if _failures == 0 else "%s failures" % _failures))
	quit(0 if _failures == 0 else 1)


func _capture(location: Node, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1600, 1000)
	location.get_node("UI").hide()
	var views := [
		["entrance", Vector3(4.25, 1.65, 3.75), Vector3(-0.4, 1.25, -2.6)],
		["commission", Vector3(0.2, 1.6, 0.8), Vector3(-3.5, 1.0, -3.2)],
		["ballot", Vector3(2.45, 1.6, -3.25), Vector3(2.45, 0.92, -4.2)],
		["urn", Vector3(2.55, 1.58, 0.6), Vector3(2.55, 0.82, -0.38)],
		["waiting", Vector3(-0.2, 1.6, 0.6), Vector3(-5.1, 1.1, 1.4)],
	]
	for view in views:
		_camera.global_position = view[1]
		_camera.look_at(view[2])
		for frame in 90:
			await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(directory.path_join(view[0] + ".png"))
		_check(result == OK, "Could not save rendered view")
		print("Captured %s; FPS=%s; draw calls=%s" % [view[0], Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
