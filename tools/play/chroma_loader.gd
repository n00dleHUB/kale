extends Node


func _ready() -> void:
	var file := FileAccess.open("user://_kale_chroma_data.json", FileAccess.READ)
	if not file:
		return
	var data := JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return

	var Materials = load("res://addons/Kale/tools/chroma/chroma_materials.gd")
	if not Materials:
		return

	var root := get_tree().current_scene
	for np_str in data.keys():
		var node := root.get_node_or_null(np_str)
		if not node:
			continue
		var d: Dictionary = data[np_str]

		var mat = Materials.create_material(
			d.get("preset", "Basic"),
			d.get("color", Color.WHITE),
			d.get("specular", 0.5),
			d.get("roughness", 0.5),
			d.get("opacity", 1.0),
			d.get("double_sided", true),
			d.get("custom_texture", ""),
			d.get("tiling_x", 1.0) * d.get("tiling_scale", 1.0),
			d.get("tiling_y", 1.0) * d.get("tiling_scale", 1.0),
			d.get("uv_space", 0),
			d.get("uv_mode", "projected"),
			d.get("pattern", "None"),
			d.get("bomb", false)
		)

		if node is MeshInstance3D:
			node.material_override = mat
		elif node is MultiMeshInstance3D:
			node.material = mat

	queue_free()
