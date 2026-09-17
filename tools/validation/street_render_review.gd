extends SceneTree
## Render the actual gameplay scene and record steady frame timings.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var directory := "res://.godot/street_review"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-dir="):
			directory = argument.trim_prefix("--review-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/locations/polling_station.tscn")
	await scene_changed
	var location := current_scene
	var player: Node3D = location.get_node("Player")
	player.set_physics_process(false)
	player.set_process(false)
	player.set_process_unhandled_input(false)
	location.get_node("UI").hide()
	var camera: Camera3D = player.get_node("Camera3D")
	var transition: Node = location.get_node("LocationTransition")
	var street_offset: Vector3 = location.get_node("Street").position
	var views := [
		["interior", false, Vector3(4.25, 1.75, 3.75), Vector3(-1, 1.4, -2)],
		["street", true, street_offset + Vector3(6, 1.65, -3.3), street_offset + Vector3(-2, 2, 7)],
		["entrance", true, street_offset + Vector3(0, 1.65, 3), street_offset + Vector3(4, 2.3, -5)],
	]
	var measurements: Dictionary = {}
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	for view in views:
		transition._apply_transition(view[1])
		camera.global_position = view[2]
		camera.look_at(view[3])
		player.reset_physics_interpolation()
		for frame in 100:
			await process_frame
		var samples: Array[float] = []
		var last_tick := Time.get_ticks_usec()
		for frame in 90:
			await process_frame
			var tick := Time.get_ticks_usec()
			samples.append((tick - last_tick) / 1000.0)
			last_tick = tick
		samples.sort()
		measurements[view[0]] = {
			"median_ms": samples[45], "p95_ms": samples[85],
			"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		}
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(view[0] + ".png"))
		print("REVIEW ", view[0], ": ", measurements[view[0]])
	# Sample the live camera at render cadence, which catches a 60 Hz stair-step
	# that route/collision tests using move_and_collide cannot detect.
	player.set_process(true)
	player.set_physics_process(true)
	var motion_passed := true
	for outside in [false, true]:
		transition._apply_transition(outside)
		Input.action_press("move_forward")
		for frame in 8:
			await process_frame
		var last_position := camera.global_position
		var moving_frames := 0
		var largest_step := 0.0
		var backwards_steps := 0
		for frame in 100:
			await process_frame
			var motion := camera.global_position - last_position
			if motion.length() > 0.00001:
				moving_frames += 1
			largest_step = maxf(largest_step, motion.length())
			if motion.z * (1.0 if outside else -1.0) < -0.0001:
				backwards_steps += 1
			last_position = camera.global_position
		Input.action_release("move_forward")
		var label := "outdoor_motion" if outside else "indoor_motion"
		measurements[label] = {"moving_frames_of_100": moving_frames,
			"largest_step_m": largest_step, "backwards_steps": backwards_steps}
		motion_passed = motion_passed and moving_frames >= 90 and backwards_steps == 0 and largest_step < 0.15
		print("REVIEW ", label, ": ", measurements[label])
	var file := FileAccess.open(directory.path_join("timings.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements, "\t"))
	print("RENDER CAMERA CHECK: ", "PASS" if motion_passed else "FAIL")
	quit(0 if motion_passed else 1)
