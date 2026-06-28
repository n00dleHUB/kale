extends Node

var spawn_position: Vector3
var spawn_rotation_y: float
var third_person_view: bool


func _ready() -> void:
	var player = load("res://addons/Kale/tools/play/playtest_player.gd").new()
	player.name = "_PlaytestPlayer"
	player.third_person = third_person_view

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.5
	col.shape = shape
	player.add_child(col)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	player.add_child(cam)

	var parent := get_parent()
	parent.add_child(player)
	player.owner = parent

	player.global_position = spawn_position
	player.global_rotation = Vector3(0, spawn_rotation_y, 0)

	queue_free()
