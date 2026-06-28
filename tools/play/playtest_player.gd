@tool
extends CharacterBody3D

var mouse_sensitivity := 0.002
var move_speed := 5.0
var jump_velocity := 4.5

var pitch := 0.0
var yaw := 0.0

@onready var camera := $Camera3D as Camera3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	yaw = rotation.y
	camera.make_current()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pitch -= event.relative.y * mouse_sensitivity
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var raw := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		0,
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)),
	)
	var wish_dir := raw.rotated(Vector3.UP, yaw).normalized()

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	velocity.x = wish_dir.x * move_speed
	velocity.z = wish_dir.z * move_speed
	move_and_slide()

	var head := global_position + Vector3(0, 1.5, 0)
	rotation.y = yaw
	camera.global_position = head
	camera.rotation.x = pitch
	camera.rotation.y = 0
	camera.rotation.z = 0
