@tool
extends Node

const CACHE_DIR := "res://addons/Kale/tools/chroma/cache/"


static func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var gdignore := CACHE_DIR + ".gdignore"
	if not FileAccess.file_exists(gdignore):
		var f := FileAccess.open(gdignore, FileAccess.WRITE)
		if f:
			f.close()


static func _get_cache_path(scene_root: Node) -> String:
	if not scene_root or scene_root.scene_file_path.is_empty():
		return ""
	_ensure_cache_dir()
	var hash_str := scene_root.scene_file_path.md5_text()
	return CACHE_DIR + "chroma_" + hash_str + ".cfg"


static func save(scene_root: Node, assignments: Dictionary) -> void:
	var path := _get_cache_path(scene_root)
	if path.is_empty():
		return

	var config := ConfigFile.new()
	config.set_value("meta", "scene_path", scene_root.scene_file_path)

	for np_str in assignments.keys():
		var data: Dictionary = assignments[np_str]
		config.set_value("nodes", np_str, data)

	if assignments.size() > 0:
		config.save(path)
	else:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


static func load_for_scene(scene_root: Node) -> Dictionary:
	var path := _get_cache_path(scene_root)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}

	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {}
	if not config.has_section("nodes"):
		return {}

	var result: Dictionary = {}
	var keys := config.get_section_keys("nodes")
	for k in keys:
		var data = config.get_value("nodes", k)
		if typeof(data) == TYPE_DICTIONARY:
			result[k] = data

	return result


static func has_cache(scene_root: Node) -> bool:
	var path := _get_cache_path(scene_root)
	return not path.is_empty() and FileAccess.file_exists(path)


static func clear_all() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		return
	var dir := DirAccess.open(CACHE_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".cfg"):
			dir.remove(f)
		f = dir.get_next()
	dir.list_dir_end()


static func get_cache_dir_path() -> String:
	_ensure_cache_dir()
	return ProjectSettings.globalize_path(CACHE_DIR)
