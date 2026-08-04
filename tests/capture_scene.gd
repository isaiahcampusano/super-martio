extends Node


func _ready() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: --script capture_scene.gd -- <scene-path> <output-png>")
		get_tree().quit(2)
		return
	var packed := load(args[0]) as PackedScene
	if packed == null:
		push_error("Could not load capture scene: %s" % args[0])
		get_tree().quit(2)
		return
	var instance := packed.instantiate()
	get_tree().root.add_child(instance)
	for frame in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_tree().root.get_texture().get_image()
	var error := image.save_png(args[1])
	if error != OK:
		push_error("Could not write capture: %s" % error_string(error))
		get_tree().quit(2)
		return
	print("Saved capture to %s" % args[1])
	get_tree().quit(0)

