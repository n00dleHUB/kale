extends CharacterBody3D

var mouse_sensitivity := 0.002
var move_speed := 5.0
var jump_velocity := 4.5
var camera_distance := 3.0

var third_person := false
var pitch := 0.0
var yaw := 0.0
var _t_was_pressed := false

@onready var camera := $Camera3D as Camera3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	yaw = rotation.y
	camera.current = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pitch -= event.relative.y * mouse_sensitivity
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var t_down := Input.is_key_pressed(KEY_T)
	if t_down and not _t_was_pressed:
		third_person = not third_person
	_t_was_pressed = t_down

	var raw := Vector3(
		Input.get_axis(KEY_A, KEY_D),
		0,
		Input.get_axis(KEY_W, KEY_S),
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

	if third_person:
		var offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch) + 0.5,
			cos(yaw) * cos(pitch),
		)
		camera.global_position = head + offset * camera_distance
		camera.look_at(head)
	else:
		camera.global_position = head
		camera.rotation.x = pitch
		camera.rotation.y = 0
		camera.rotation.z = 0
