@tool
class_name KaleBase
extends Node


func get_tool_name() -> String:
	return "Tool"


func build_panel() -> Control:
	return Control.new()


func on_editor_scene_changed(_root: Node) -> void:
	pass
