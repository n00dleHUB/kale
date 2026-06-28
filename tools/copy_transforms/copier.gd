@tool
extends Node

class_name CopyTransforms


static func copy_position(source: Node3D, target: Node3D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(source):
		return
	target.position = source.position


static func copy_rotation(source: Node3D, target: Node3D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(source):
		return
	target.quaternion = source.quaternion


static func copy_scale(source: Node3D, target: Node3D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(source):
		return
	target.scale = source.scale


static func copy_all(source: Node3D, target: Node3D, pos: bool, rot: bool, scl: bool) -> void:
	if pos:
		copy_position(source, target)
	if rot:
		copy_rotation(source, target)
	if scl:
		copy_scale(source, target)
