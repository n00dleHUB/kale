@tool
extends KaleBase

var _view_mode: OptionButton


func get_tool_name() -> String:
	return "Play"


func build_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)

	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.pressed.connect(_on_play)
	panel.add_child(play_btn)

	_view_mode = OptionButton.new()
	_view_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_mode.add_item("First Person")
	_view_mode.add_item("Third Person")
	_view_mode.select(0)
	panel.add_child(_view_mode)

	return panel


func _on_play() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	_cleanup()

	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var cam := viewport.get_camera_3d() if viewport else null
	if not cam:
		return

	var SpawnerScript := load("res://addons/Kale/tools/play/player_spawner.gd")
	var spawner := SpawnerScript.new()
	spawner.name = "_PlayerSpawner"
	spawner.spawn_position = cam.global_position
	spawner.spawn_rotation_y = cam.global_rotation.y
	spawner.third_person_view = _view_mode.selected == 1
	root.add_child(spawner, true)

	EditorInterface.play_current_scene()


func _cleanup() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	for name in ["_PlaytestPlayer", "_PlayerSpawner"]:
		var node := root.get_node_or_null(name)
		if node:
			node.queue_free()
