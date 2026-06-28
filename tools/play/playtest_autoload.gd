extends Node


func _ready() -> void:
	var spawn_file := FileAccess.open("user://_kale_spawn.cfg", FileAccess.READ)
	if not spawn_file:
		return

	var data := JSON.parse_string(spawn_file.get_as_text())
	spawn_file.close()
	DirAccess.remove_absolute("user://_kale_spawn.cfg")

	if typeof(data) != TYPE_DICTIONARY:
		return

	var pos_arr := data.get("position", [0, 2, 0])
	var pos := Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	var rot_y := data.get("rotation_y", 0.0)
	var third_person := data.get("third_person", false)

	var player_scene := preload("res://addons/Kale/tools/play/player.tscn")
	var player := player_scene.instantiate()
	player.name = "_PlaytestPlayer"
	player.third_person = third_person

	var scene_root := get_tree().current_scene
	scene_root.add_child(player)
	player.owner = scene_root
	player.global_position = pos
	player.global_rotation = Vector3(0, rot_y, 0)
