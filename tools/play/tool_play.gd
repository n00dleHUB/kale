@tool
extends KaleBase

const PLAYER_NAME := "_PlaytestPlayer"
const PLAYER_SCRIPT := preload("res://addons/Kale/tools/play/playtest_player.gd")

var _view_mode: OptionButton
var _player_scene: PackedScene


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
	_spawn_player()
	EditorInterface.play_current_scene()


func _get_player_scene() -> PackedScene:
	if _player_scene:
		return _player_scene

	var root := CharacterBody3D.new()
	root.name = "Player"

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.5
	col.shape = shape
	root.add_child(col)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	root.add_child(cam)

	root.set_script(PLAYER_SCRIPT)

	var packed := PackedScene.new()
	packed.pack(root)
	_player_scene = packed
	return _player_scene


func _spawn_player() -> void:
	var root_node := EditorInterface.get_edited_scene_root()
	if not root_node:
		return

	_remove_player()

	var viewport := EditorInterface.get_editor_viewport_3d(0)
	if not viewport:
		return
	var cam := viewport.get_camera_3d()
	if not cam:
		return

	var player := _get_player_scene().instantiate()
	player.name = PLAYER_NAME

	root_node.add_child(player, true)
	player.set_owner(root_node)

	player.global_position = cam.global_position
	player.global_rotation = Vector3(0, cam.global_rotation.y, 0)
	player.third_person = _view_mode.selected == 1


func _remove_player() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var player := root.get_node_or_null(PLAYER_NAME)
	if player:
		player.queue_free()
