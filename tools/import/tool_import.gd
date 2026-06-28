@tool
extends KaleBase

const DEFAULT_FOLDER := "res://prefabs/"
const MODE_VERSION := 0
const MODE_DATE := 1

var _panel: VBoxContainer
var _folder_input: LineEdit
var _search_input: LineEdit
var _mode_dropdown: OptionButton
var _make_local: CheckBox
var _status: Label


func get_tool_name() -> String:
	return "Import"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(320, 0)

	# Folder path
	var folder_lbl = Label.new()
	folder_lbl.text = "Folder:"
	_panel.add_child(folder_lbl)

	_folder_input = LineEdit.new()
	_folder_input.text = DEFAULT_FOLDER
	_panel.add_child(_folder_input)

	# Search term
	var search_lbl = Label.new()
	search_lbl.text = "Search:"
	_panel.add_child(search_lbl)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "e.g. myAsset_* or myAsset_v*"
	_panel.add_child(_search_input)

	# Mode dropdown
	var mode_lbl = Label.new()
	mode_lbl.text = "Mode:"
	_panel.add_child(mode_lbl)

	_mode_dropdown = OptionButton.new()
	_mode_dropdown.add_item("Latest Version", MODE_VERSION)
	_mode_dropdown.add_item("Latest Date", MODE_DATE)
	_mode_dropdown.selected = MODE_VERSION
	_panel.add_child(_mode_dropdown)

	# Make Local toggle
	_make_local = CheckBox.new()
	_make_local.text = "Make Local"
	_make_local.button_pressed = true
	_panel.add_child(_make_local)

	# Import button
	var import_btn = Button.new()
	import_btn.text = "Import"
	import_btn.pressed.connect(_on_import_pressed)
	_panel.add_child(import_btn)

	# Status label
	_status = Label.new()
	_status.text = ""
	_panel.add_child(_status)

	return _panel


func _on_import_pressed() -> void:
	var folder := _folder_input.text.strip_edges()
	var search := _search_input.text.strip_edges()

	if folder.is_empty() or search.is_empty():
		_flash_status("Enter a folder and search term", Color(1, 0.5, 0))
		return

	var prefix := search.split("*")[0]
	if prefix.is_empty():
		_flash_status("Enter a search prefix", Color(1, 0.5, 0))
		return

	var files := _find_tscn_files(folder, prefix)
	if files.is_empty():
		_flash_status("No files matched \"" + prefix + "*\"", Color(1, 0.3, 0))
		return

	var chosen := _pick_best(files, prefix)
	if chosen.is_empty():
		_flash_status("No files matched \"" + prefix + "*\"", Color(1, 0.3, 0))
		return

	_do_import(chosen)


func _find_tscn_files(folder: String, prefix: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(folder)
	if not dir:
		return result

	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tscn") and f.begins_with(prefix):
			result.append(f)
		f = dir.get_next()
	dir.list_dir_end()

	return result


func _pick_best(files: Array[String], prefix: String) -> String:
	var mode := _mode_dropdown.get_selected_id()

	if mode == MODE_VERSION:
		return _pick_latest_version(files, prefix)
	else:
		return _pick_latest_date(files)


func _pick_latest_version(files: Array[String], prefix: String) -> String:
	var best_file := ""
	var best_version := -1
	var re := RegEx.new()
	re.compile("_v(\\d+)")

	for f in files:
		var suffix := f.trim_prefix(prefix)
		var mt := re.search(suffix)
		var version := 0
		if mt:
			version = int(mt.get_string(1))
		if version > best_version:
			best_version = version
			best_file = f
		elif version == best_version and best_file.is_empty():
			best_file = f

	return best_file


func _pick_latest_date(files: Array[String]) -> String:
	var best_file := ""
	var best_time := -1.0
	var folder := _folder_input.text.strip_edges()

	for f in files:
		var path := folder.trim_suffix("/") + "/" + f
		var mtime := FileAccess.get_modified_time(path)
		if mtime > best_time:
			best_time = mtime
			best_file = f

	return best_file


func _do_import(filename: String) -> void:
	var folder := _folder_input.text.strip_edges().trim_suffix("/")
	var path := folder + "/" + filename

	var scene := load(path) as PackedScene
	if not scene:
		_flash_status("Failed to load: " + filename, Color(1, 0.3, 0))
		return

	var root := EditorInterface.get_edited_scene_root()
	if not root:
		_flash_status("Open a scene first", Color(1, 0.5, 0))
		return

	var instance := scene.instantiate()
	root.add_child(instance)
	instance.owner = root

	if _make_local.button_pressed:
		_unpack(instance)

	_set_status("Imported " + filename.trim_suffix(".tscn"), Color(0, 1, 0))


func _unpack(node: Node) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	node.scene_file_path = ""
	for child in node.get_children(true):
		child.owner = root


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _flash_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)

	if text.is_empty():
		return

	await get_tree().create_timer(1.5).timeout
	if _status and is_instance_valid(_status) and _status.text == text:
		_status.text = ""
