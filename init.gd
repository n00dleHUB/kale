@tool
extends EditorPlugin

var _dock: Control
var _was_playing := false


func _enter_tree():
	const TR = preload("res://addons/Kale/tools/tool_registry.gd")
	_dock = TR.build_tab_dock(self)
	_dock.name = "Kale"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	scene_changed.connect(_on_scene_changed)


func _process(_delta: float) -> void:
	var is_playing := EditorInterface.is_playing_scene()
	if _was_playing and not is_playing:
		_cleanup_playtest()
	_was_playing = is_playing


func _cleanup_playtest() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var node := root.get_node_or_null("_PlaytestPlayer")
	if node:
		node.queue_free()


func _exit_tree():
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()


func _on_scene_changed(root: Node) -> void:
	_notify_tools(root)


func _notify_tools(root: Node) -> void:
	if not is_instance_valid(_dock):
		return
	for i in _dock.get_child_count():
		var tab := _dock.get_child(i)
		for child in tab.get_children():
			if child is KaleBase:
				child.on_editor_scene_changed(root)
