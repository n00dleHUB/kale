@tool
extends KaleBase


func get_tool_name() -> String:
	return "Play"


func build_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)

	var btn := Button.new()
	btn.text = "Play"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		EditorInterface.play_current_scene()
	)
	panel.add_child(btn)

	return panel
