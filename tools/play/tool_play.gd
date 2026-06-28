@tool
extends KaleBase

const AUTOLOAD_NAME := "KaleAutoload"
const AUTOLOAD_PATH := "res://addons/Kale/tools/play/playtest_autoload.gd"

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
	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var cam := viewport.get_camera_3d() if viewport else null
	if not cam:
		return

	var data := {
		position = [cam.global_position.x, cam.global_position.y, cam.global_position.z],
		rotation_y = cam.global_rotation.y,
		third_person = _view_mode.selected == 1,
	}

	var file := FileAccess.open("user://_kale_spawn.cfg", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	if _plugin:
		_plugin.add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	EditorInterface.play_current_scene()
