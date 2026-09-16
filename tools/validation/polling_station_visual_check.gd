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
	for step in 400:
		var motion := target - _player.position
		if motion.length() < 0.015:
			return
		_player.move_and_collide(motion.limit_length(0.05))
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
	var controller: Node = location.get_node("IntroController")
	var booth: Area3D = location.get_node("VotingBooth/InteractionArea")
	var urn: Area3D = location.get_node("BallotBox/InteractionArea")
	var ui: CanvasLayer = location.get_node("UI")
	await physics_frame
	urn.request_interaction()
	_check(controller.state == 0, "Urn accepted an empty ballot")
	await _walk(Vector3(0, 0, 2.8))
	await _walk(Vector3(0, 0, -1.5))
	await _walk(Vector3(-2.65, 0, -1.5))
	await _walk(Vector3(-2.65, 0, -3.05))
	_aim(booth)
	booth.request_interaction()
	_check(ui.ballot_panel.visible and not _player.movement_enabled, "Ballot did not open")
	_check(ui.confirm_button.disabled, "Empty ballot can be confirmed")
	var party_button: Button = ui.party_list.get_child(0)
	party_button.pressed.emit()
	ui.confirm_button.pressed.emit()
	_check(controller.state == 1 and not controller.selected_party_id.is_empty(), "Party selection failed")
	_check(_player.movement_enabled and not ui.ballot_panel.visible, "Movement was not restored")
	await _walk(Vector3(-2.65, 0, -1.5))
	await _walk(Vector3(1.3, 0, -1.5))
	await _walk(Vector3(1.3, 0, -2.8))
	_aim(urn)
	# Sweep the actual player capsule against the critical rigid objects.
	for sweep in [
		[Vector3(1.3, 0, -2.6), Vector3(0, 0, -1.2)],
		[Vector3(-2.0, 0, 1.8), Vector3(-1.0, 0, 0)],
		[Vector3(-2.65, 0, -3.05), Vector3(0, 0, -1.0)],
		# Keep this sweep clear of the visual-only second booth's back panel.
		[Vector3(0.55, 0, -4.3), Vector3(0, 0, -1.0)],
		[Vector3(2.55, 0, 2.35), Vector3(1.1, 0, 0)],
		[Vector3(0, 0, 5.05), Vector3(0, 0, 1.0)],
	]:
		var start := Transform3D(Basis.IDENTITY, sweep[0])
		_check(_player.test_move(start, sweep[1]), "Missing obstacle collision at %s" % sweep[0])
	urn.request_interaction()
	_check(controller.state == 2 and ui.completion_panel.visible, "Existing completion screen failed")
	_check(not _player.movement_enabled, "Movement remains enabled on completion")
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
		["entrance", Vector3(0.1, 1.65, 4.2), Vector3(-0.1, 1.3, -2)],
		["commission", Vector3(-1.65, 1.6, 3.3), Vector3(-2.95, 0.91, 1.5)],
		["ballot", Vector3(-2.64, 1.6, -3.05), Vector3(-2.68, 0.98, -3.93)],
		["urn", Vector3(0.18, 1.58, -2.2), Vector3(1.3, 0.85, -3.5)],
		["entry_doors", Vector3(-1.0, 1.6, 1.35), Vector3(.55, 1.3, 5.5)],
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
