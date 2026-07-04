@tool
extends KaleBase

const Presets = preload("res://addons/Kale/tools/project/project_data.gd")

var _panel: VBoxContainer
var _map_dropdown: OptionButton
var _sub_dropdown: OptionButton
var _sub_row: HBoxContainer
var _spawn_btn: Button
var _remove_btn: Button

var _pos_x: SpinBox
var _pos_y: SpinBox
var _pos_z: SpinBox
var _size_x: SpinBox
var _size_y: SpinBox
var _size_z: SpinBox

var _albedo_path: LineEdit
var _emission_path: LineEdit

var _emission_energy: SpinBox
var _normal_fade: SpinBox
var _upper_fade: SpinBox
var _lower_fade: SpinBox
var _modulate: ColorPickerButton

var _decal_nodes: Array[Decal] = []
var _selected_decal: Decal
var _preset_data = {}
var _multi_data: Array = []


func get_tool_name() -> String:
	return "Map Project"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(320, 0)

	var pres_lbl := Label.new()
	pres_lbl.text = "Map Preset:"
	_panel.add_child(pres_lbl)

	_map_dropdown = OptionButton.new()
	_map_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for name in Presets.get_names():
		_map_dropdown.add_item(name)
	_map_dropdown.item_selected.connect(_on_map_selected)
	_panel.add_child(_map_dropdown)

	_sub_row = HBoxContainer.new()
	_sub_dropdown = OptionButton.new()
	_sub_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sub_dropdown.item_selected.connect(_on_sub_selected)
	_sub_row.add_child(_sub_dropdown)
	_sub_row.visible = false
	_panel.add_child(_sub_row)

	var btn_row := HBoxContainer.new()
	_spawn_btn = Button.new()
	_spawn_btn.text = "Spawn Decal"
	_spawn_btn.pressed.connect(_on_spawn)
	btn_row.add_child(_spawn_btn)
	_remove_btn = Button.new()
	_remove_btn.text = "Remove Decal"
	_remove_btn.pressed.connect(_on_remove)
	btn_row.add_child(_remove_btn)
	_panel.add_child(btn_row)

	var size_body := VBoxContainer.new()
	_size_x = SpinBox.new()
	_size_x.max_value = 99999
	_size_y = SpinBox.new()
	_size_y.max_value = 99999
	_size_z = SpinBox.new()
	_size_z.max_value = 99999
	size_body.add_child(_make_vec3_row("Size X/Y/Z:", _size_x, _size_y, _size_z))
	_panel.add_child(_make_section("Size", true, size_body))

	var pos_body := VBoxContainer.new()
	_pos_x = SpinBox.new()
	_pos_x.max_value = 99999
	_pos_x.min_value = -99999
	_pos_y = SpinBox.new()
	_pos_y.max_value = 99999
	_pos_y.min_value = -99999
	_pos_z = SpinBox.new()
	_pos_z.max_value = 99999
	_pos_z.min_value = -99999
	pos_body.add_child(_make_vec3_row("Offset X/Y/Z:", _pos_x, _pos_y, _pos_z))
	_panel.add_child(_make_section("Position Offset", true, pos_body))

	var tex_body := VBoxContainer.new()
	var alb_row := HBoxContainer.new()
	var alb_lbl := Label.new()
	alb_lbl.text = "Albedo:"
	alb_row.add_child(alb_lbl)
	_albedo_path = LineEdit.new()
	_albedo_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alb_row.add_child(_albedo_path)
	var alb_browse := Button.new()
	alb_browse.text = "Browse"
	alb_browse.pressed.connect(_on_browse_albedo)
	alb_row.add_child(alb_browse)
	tex_body.add_child(alb_row)

	var em_row := HBoxContainer.new()
	var em_lbl := Label.new()
	em_lbl.text = "Emission:"
	em_row.add_child(em_lbl)
	_emission_path = LineEdit.new()
	_emission_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	em_row.add_child(_emission_path)
	var em_browse := Button.new()
	em_browse.text = "Browse"
	em_browse.pressed.connect(_on_browse_emission)
	em_row.add_child(em_browse)
	tex_body.add_child(em_row)
	_panel.add_child(_make_section("Textures", true, tex_body))

	var param_body := VBoxContainer.new()
	_emission_energy = SpinBox.new()
	_emission_energy.max_value = 100.0
	_emission_energy.step = 0.01
	param_body.add_child(_make_row("Emission Energy:", _emission_energy))

	_modulate = ColorPickerButton.new()
	_modulate.color = Color.WHITE
	_modulate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mod_row := HBoxContainer.new()
	var mod_lbl := Label.new()
	mod_lbl.text = "Modulate:"
	mod_row.add_child(mod_lbl)
	mod_row.add_child(_modulate)
	param_body.add_child(mod_row)

	_normal_fade = SpinBox.new()
	_normal_fade.max_value = 1.0
	_normal_fade.step = 0.001
	param_body.add_child(_make_row("Normal Fade:", _normal_fade))
	_panel.add_child(_make_section("Parameters", true, param_body))

	var fade_body := VBoxContainer.new()
	_upper_fade = SpinBox.new()
	_upper_fade.max_value = 10.0
	_upper_fade.step = 0.001
	fade_body.add_child(_make_row("Upper Fade:", _upper_fade))
	_lower_fade = SpinBox.new()
	_lower_fade.max_value = 10.0
	_lower_fade.step = 0.001
	fade_body.add_child(_make_row("Lower Fade:", _lower_fade))
	_panel.add_child(_make_section("Vertical Fade", true, fade_body))

	return _panel


func _make_section(title: String, collapsed: bool, body: VBoxContainer) -> VBoxContainer:
	var section := VBoxContainer.new()
	var header := Button.new()
	header.text = ("▶ " if collapsed else "▼ ") + title
	header.flat = true
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.visible = not collapsed
	header.pressed.connect(func():
		body.visible = not body.visible
		header.text = ("▶ " if not body.visible else "▼ ") + title
	)
	section.add_child(header)
	section.add_child(body)
	return section


func _make_row(label: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(100, 0)
	row.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_vec3_row(label: String, sx: SpinBox, sy: SpinBox, sz: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(100, 0)
	row.add_child(lbl)
	for spin in [sx, sy, sz]:
		spin.custom_minimum_size = Vector2(60, 0)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(_on_param_changed)
		row.add_child(spin)
	return row


func _on_map_selected(idx: int) -> void:
	var name := _map_dropdown.get_item_text(idx)
	_preset_data = Presets.get_preset(name)

	_decal_nodes = []
	_selected_decal = null
	_find_existing_decals(name)

	if _preset_data is Array:
		_multi_data = _preset_data
		_sub_dropdown.clear()
		for d in _multi_data:
			var label := "Decal " + str(_sub_dropdown.item_count + 1)
			_sub_dropdown.add_item(label)
		_sub_row.visible = true
		if _sub_dropdown.item_count > 0:
			_sub_dropdown.select(0)
			_on_sub_selected(0)
	else:
		_multi_data = []
		_sub_row.visible = false
		_update_ui_from_preset(_preset_data)
		if _decal_nodes.size() > 0:
			_selected_decal = _decal_nodes[0]
			_read_decal_to_ui(_selected_decal)


func _on_sub_selected(idx: int) -> void:
	if idx < 0 or idx >= _multi_data.size():
		return
	_update_ui_from_preset(_multi_data[idx])
	if idx < _decal_nodes.size():
		_selected_decal = _decal_nodes[idx]
		_read_decal_to_ui(_selected_decal)


func _update_ui_from_preset(data: Dictionary) -> void:
	_size_x.value = data.get("size", Vector3.ONE).x
	_size_y.value = data.get("size", Vector3.ONE).y
	_size_z.value = data.get("size", Vector3.ONE).z
	_pos_x.value = 0.0
	_pos_y.value = 0.0
	_pos_z.value = 0.0
	_albedo_path.text = data.get("tex", "")
	_emission_path.text = data.get("tex", "")
	_emission_energy.value = data.get("ee", 0.0)
	_normal_fade.value = data.get("nf", 0.0)
	_upper_fade.value = data.get("uf", 0.3)
	_lower_fade.value = data.get("lf", 0.3)


func _read_decal_to_ui(decal: Decal) -> void:
	if not decal or not is_instance_valid(decal):
		return
	_size_x.value = decal.size.x
	_size_y.value = decal.size.y
	_size_z.value = decal.size.z
	_pos_x.value = decal.position.x - _preset_data.get("pos", Vector3.ZERO).x if not (_preset_data is Array) else 0.0
	_pos_y.value = decal.position.y - _preset_data.get("pos", Vector3.ZERO).y if not (_preset_data is Array) else 0.0
	_pos_z.value = decal.position.z - _preset_data.get("pos", Vector3.ZERO).z if not (_preset_data is Array) else 0.0
	_emission_energy.value = decal.emission_energy
	_normal_fade.value = decal.normal_fade
	_upper_fade.value = decal.upper_fade
	_lower_fade.value = decal.lower_fade
	_modulate.color = decal.modulate


func _find_existing_decals(map_name: String) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	_decal_nodes = []
	for child in root.find_children("*", "Decal", true, false):
		if child.has_meta("map_project") and child.get_meta("map_project") == map_name:
			_decal_nodes.append(child)
	_decal_nodes.sort_custom(func(a, b): return a.name < b.name)


func _on_spawn() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var map_name := _map_dropdown.get_item_text(_map_dropdown.selected)
	if map_name.is_empty():
		return

	# Remove existing decals for this map
	_on_remove()

	if _preset_data is Array:
		var i := 0
		for entry in _preset_data:
			_spawn_single_decal(root, map_name + "_" + str(i), entry, map_name)
			i += 1
	else:
		_spawn_single_decal(root, map_name, _preset_data, map_name)

	_find_existing_decals(map_name)
	if _decal_nodes.size() > 0:
		_selected_decal = _decal_nodes[0]
		if _multi_data.size() > 0 and _sub_dropdown.item_count > 0:
			_sub_dropdown.select(0)
			_on_sub_selected(0)


func _spawn_single_decal(root: Node, name: String, data, map_name: String) -> void:
	var decal := Decal.new()
	decal.name = "MapProjection_" + name
	decal.set_meta("map_project", map_name)

	var pos: Vector3 = data.get("pos", Vector3.ZERO) if data is Dictionary else Vector3.ZERO
	decal.position = pos
	decal.size = data.get("size", Vector3.ONE) if data is Dictionary else Vector3.ONE

	var tex_path: String = data.get("tex", "") if data is Dictionary else ""
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		decal.texture_albedo = load(tex_path)
		decal.texture_emission = load(tex_path)

	decal.emission_energy = data.get("ee", 0.0) if data is Dictionary else 0.0
	decal.normal_fade = data.get("nf", 0.0) if data is Dictionary else 0.0
	decal.upper_fade = data.get("uf", 0.3) if data is Dictionary else 0.3
	decal.lower_fade = data.get("lf", 0.3) if data is Dictionary else 0.3

	root.add_child(decal, true)
	decal.set_owner(root)


func _on_remove() -> void:
	for d in _decal_nodes:
		if is_instance_valid(d):
			d.queue_free()
	_decal_nodes = []
	_selected_decal = null


func _on_param_changed(_v: float) -> void:
	if _selected_decal and is_instance_valid(_selected_decal):
		_update_decal_from_ui(_selected_decal)


func _update_decal_from_ui(decal: Decal) -> void:
	if not decal or not is_instance_valid(decal):
		return

	decal.position = Vector3(
		decal.position.x + _pos_x.value,
		decal.position.y + _pos_y.value,
		decal.position.z + _pos_z.value
	)
	decal.size = Vector3(_size_x.value, _size_y.value, _size_z.value)

	if ResourceLoader.exists(_albedo_path.text):
		decal.texture_albedo = load(_albedo_path.text)
	if ResourceLoader.exists(_emission_path.text):
		decal.texture_emission = load(_emission_path.text)

	decal.emission_energy = _emission_energy.value
	decal.modulate = _modulate.color
	decal.normal_fade = _normal_fade.value
	decal.upper_fade = _upper_fade.value
	decal.lower_fade = _lower_fade.value


func _on_browse_albedo() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.add_filter("*.jpg,*.png,*.webp,*.exr,*.hdr", "Textures")
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_selected.connect(func(p: String): _albedo_path.text = p; _on_param_changed(0.0))
	fd.popup_centered(Vector2i(600, 400))
	_panel.add_child(fd)


func _on_browse_emission() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.add_filter("*.jpg,*.png,*.webp,*.exr,*.hdr", "Textures")
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_selected.connect(func(p: String): _emission_path.text = p; _on_param_changed(0.0))
	fd.popup_centered(Vector2i(600, 400))
	_panel.add_child(fd)


func on_editor_scene_changed(_root: Node) -> void:
	_decal_nodes = []
	_selected_decal = null
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var found := false
	for child in root.find_children("*", "Decal", true, false):
		if child.has_meta("map_project"):
			var map_name: String = child.get_meta("map_project")
			var idx := _map_dropdown.get_item_index(map_name)
			if idx >= 0:
				_map_dropdown.select(idx)
				_on_map_selected(idx)
				found = true
				break
