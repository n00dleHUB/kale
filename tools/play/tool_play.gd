@tool
extends KaleBase

const PLAYER_SCENE := preload("res://addons/Kale/tools/play/player.tscn")

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

	var scene_path := root.scene_file_path
	if scene_path.is_empty():
		return

	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var cam := viewport.get_camera_3d() if viewport else null
	if not cam:
		return

	var wrapper := Node3D.new()
	wrapper.name = "KalePlaytest"

	var user_scene = load(scene_path).instantiate()
	wrapper.add_child(user_scene)
	user_scene.owner = wrapper

	var player := PLAYER_SCENE.instantiate()
	player.name = "_PlaytestPlayer"
	player.global_position = cam.global_position
	player.global_rotation = Vector3(0, cam.global_rotation.y, 0)
	player.third_person = _view_mode.selected == 1
	wrapper.add_child(player)
	player.owner = wrapper

	var wrapper_path := "user://_kale_wrapper.tscn"
	var packed := PackedScene.new()
	packed.pack(wrapper)
	ResourceSaver.save(packed, wrapper_path)

	EditorInterface.play_custom_scene(wrapper_path)
