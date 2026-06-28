@tool
extends KaleBase

const PLAYER_NAME := "_PlaytestPlayer"
const PLAYER_SCENE := preload("res://addons/Kale/tools/play/player.tscn")


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

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 4)
	sep.color = Color(0.25, 0.25, 0.25)
	panel.add_child(sep)

	var add_btn := Button.new()
	add_btn.text = "Add Player"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.pressed.connect(_add_player)
	panel.add_child(add_btn)

	var remove_btn := Button.new()
	remove_btn.text = "Remove Player"
	remove_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_btn.pressed.connect(_remove_player)
	panel.add_child(remove_btn)

	return panel


func _on_play() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root:
		_save_chroma_json(root)
		_add_chroma_loader(root)

	var err := EditorInterface.save_scene()
	if err != OK:
		push_warning("Kale Play: scene save failed (", err, ")")
	EditorInterface.play_current_scene()


func _save_chroma_json(root: Node) -> void:
	var data: Dictionary = {}
	var nodes: Array[Node] = []
	_gather_chroma_nodes(root, nodes)
	for n in nodes:
		if n.has_meta("chroma_params"):
			data[root.get_path_to(n)] = n.get_meta("chroma_params")

	if data.is_empty():
		return

	var file := FileAccess.open("user://_kale_chroma_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _add_chroma_loader(root: Node) -> void:
	if not FileAccess.file_exists("user://_kale_chroma_data.json"):
		return

	var loader_script = load("res://addons/Kale/tools/play/chroma_loader.gd")
	var loader = loader_script.new()
	loader.name = "_KaleChromaLoader"
	root.add_child(loader, true)
	loader.set_owner(root)


func _gather_chroma_nodes(n: Node, out: Array[Node]) -> void:
	if (n is MeshInstance3D or n is MultiMeshInstance3D) and n.has_meta("chroma_applied"):
		out.append(n)
	for c in n.get_children():
		_gather_chroma_nodes(c, out)


func _add_player() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	_remove_player()

	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var cam := viewport.get_camera_3d() if viewport else null
	if not cam:
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = PLAYER_NAME

	root.add_child(player, true)
	player.set_owner(root)
	player.global_position = cam.global_position + (-cam.global_transform.basis.z * 3.0)
	player.global_rotation = Vector3(0, cam.global_rotation.y, 0)


func _remove_player() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	for child in root.get_children():
		if child.name.begins_with(PLAYER_NAME):
			child.free()
