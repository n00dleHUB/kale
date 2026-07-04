@tool
extends KaleBase

const Presets = preload("res://addons/Kale/tools/project/project_data.gd")

var _panel: VBoxContainer
var _map_dropdown: OptionButton
var _spawn_btn: Button
var _remove_btn: Button

var _pos_x: SpinBox
var _pos_y: SpinBox
var _pos_z: SpinBox
var _size_x: SpinBox
var _size_y: SpinBox
var _size_z: SpinBox

var _albedo_path: LineEdit
var _albedo_browse: Button
var _emission_path: LineEdit
var _emission_browse: Button

var _emission_energy: SpinBox
var _normal_fade: SpinBox
var _upper_fade: SpinBox
var _lower_fade: SpinBox
var _modulate: ColorPickerButton

var _decal_node: Decal
var _preset_pos: Vector3


func get_tool_name() -> String:
	return "Map Project"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(320, 0)

	# ── Map Preset section ──
	var pres_lbl := Label.new()
	pres_lbl.text = "Map Preset:"
	_panel.add_child(pres_lbl)

	_map_dropdown = OptionButton.new()
	_map_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for name in Presets.get_names():
		_map_dropdown.add_item(name)
	_map_dropdown.item_selected.connect(_on_map_selected)
	_panel.add_child(_map_dropdown)

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

	# ── Size section ──
	var size_body := VBoxContainer.new()
	_size_x = SpinBox.new()
	_size_x.max_value = 99999
	_size_y = SpinBox.new()
	_size_y.max_value = 99999
	_size_z = SpinBox.new()
	_size_z.max_value = 99999
	size_body.add_child(_make_vec3_row("Size X/Y/Z:", _size_x, _size_y, _size_z))
	_panel.add_child(_make_section("Size", true, size_body))

	# ── Position Offset section ──
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

	# ── Textures section ──
	var tex_body := VBoxContainer.new()
	var alb_row := HBoxContainer.new()
	var alb_lbl := Label.new()
	alb_lbl.text = "Albedo:"
	alb_row.add_child(alb_lbl)
	_albedo_path = LineEdit.new()
	_albedo_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alb_row.add_child(_albedo_path)
	_albedo_browse = Button.new()
	_albedo_browse.text = "Browse"
	_albedo_browse.pressed.connect(_on_browse_albedo)
	alb_row.add_child(_albedo_browse)
	tex_body.add_child(alb_row)

	var em_row := HBoxContainer.new()
	var em_lbl := Label.new()
	em_lbl.text = "Emission:"
	em_row.add_child(em_lbl)
	_emission_path = LineEdit.new()
	_emission_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	em_row.add_child(_emission_path)
	_emission_browse = Button.new()
	_emission_browse.text = "Browse"
	_emission_browse.pressed.connect(_on_browse_emission)
	em_row.add_child(_emission_browse)
	tex_body.add_child(em_row)
	_panel.add_child(_make_section("Textures", true, tex_body))

	# ── Parameters section ──
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

	# ── Vertical Fade section ──
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
	var preset := Presets.get_preset(name)
	if preset.is_empty():
		return

	_preset_pos = preset.get("pos", Vector3.ZERO)
	var sz: Vector3 = preset.get("size", Vector3.ONE)
	_size_x.value = sz.x
	_size_y.value = sz.y
	_size_z.value = sz.z
	_pos_x.value = 0.0
	_pos_y.value = 0.0
	_pos_z.value = 0.0
	_albedo_path.text = preset.get("tex", "")
	_emission_path.text = preset.get("tex", "")
	_emission_energy.value = preset.get("ee", 0.0)
	_normal_fade.value = preset.get("nf", 0.0)
	_upper_fade.value = preset.get("uf", 0.3)
	_lower_fade.value = preset.get("lf", 0.3)

	# Try to find existing decal for this map
	_find_existing_decal()


func _find_existing_decal() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	_decal_node = null
	for child in root.find_children("*", "Decal", true, false):
		if child.has_meta("map_project") and child.get_meta("map_project") == _map_dropdown.get_item_text(_map_dropdown.selected):
			_decal_node = child
			break
	if _decal_node:
		_size_x.value = _decal_node.size.x
		_size_y.value = _decal_node.size.y
		_size_z.value = _decal_node.size.z
		var offset := _decal_node.position - _preset_pos
		_pos_x.value = offset.x
		_pos_y.value = offset.y
		_pos_z.value = offset.z


func _on_spawn() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var map_name := _map_dropdown.get_item_text(_map_dropdown.selected)
	if map_name.is_empty():
		return

	# Remove existing decal for this map first
	if _decal_node and is_instance_valid(_decal_node):
		_decal_node.queue_free()

	_decal_node = Decal.new()
	_decal_node.name = "MapProjection_" + map_name
	_decal_node.set_meta("map_project", map_name)
	root.add_child(_decal_node, true)
	_decal_node.set_owner(root)

	_update_decal_from_ui()
	_save_cache()


func _on_remove() -> void:
	if _decal_node and is_instance_valid(_decal_node):
		_decal_node.queue_free()
		_decal_node = null


func _on_param_changed(_v: float) -> void:
	if _decal_node and is_instance_valid(_decal_node):
		_update_decal_from_ui()


func _update_decal_from_ui() -> void:
	if not _decal_node or not is_instance_valid(_decal_node):
		return

	var map_name := _map_dropdown.get_item_text(_map_dropdown.selected)
	var preset := Presets.get_preset(map_name)
	var base_pos: Vector3 = preset.get("pos", Vector3.ZERO) if not preset.is_empty() else Vector3.ZERO

	_decal_node.position = base_pos + Vector3(_pos_x.value, _pos_y.value, _pos_z.value)
	_decal_node.size = Vector3(_size_x.value, _size_y.value, _size_z.value)

	if ResourceLoader.exists(_albedo_path.text):
		_decal_node.texture_albedo = load(_albedo_path.text)
	if ResourceLoader.exists(_emission_path.text):
		_decal_node.texture_emission = load(_emission_path.text)

	_decal_node.emission_energy = _emission_energy.value
	_decal_node.modulate = _modulate.color
	_decal_node.normal_fade = _normal_fade.value
	_decal_node.upper_fade = _upper_fade.value
	_decal_node.lower_fade = _lower_fade.value


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


func _save_cache() -> void:
	var map_name := _map_dropdown.get_item_text(_map_dropdown.selected)
	if map_name.is_empty():
		return
	if not _decal_node or not is_instance_valid(_decal_node):
		return

	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var data := {
		"map": map_name,
		"pos": [_decal_node.position.x, _decal_node.position.y, _decal_node.position.z],
		"size": [_decal_node.size.x, _decal_node.size.y, _decal_node.size.z],
		"albedo": _albedo_path.text,
		"emission": _emission_path.text,
		"ee": _emission_energy.value,
		"modulate": [_modulate.color.r, _modulate.color.g, _modulate.color.b, _modulate.color.a],
		"nf": _normal_fade.value,
		"uf": _upper_fade.value,
		"lf": _lower_fade.value,
	}
	var cache_path := "res://addons/Kale/tools/project/cache/"
	if not DirAccess.dir_exists_absolute(cache_path):
		DirAccess.make_dir_recursive_absolute(cache_path)
	var config := ConfigFile.new()
	config.set_value("project", "data", data)
	config.save(cache_path + "project_" + map_name + ".cfg")


func on_editor_scene_changed(_root: Node) -> void:
	# Auto-find existing decals in the new scene
	_decal_node = null
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	for child in root.find_children("*", "Decal", true, false):
		if child.has_meta("map_project"):
			_decal_node = child
			var idx := _map_dropdown.get_item_index(child.get_meta("map_project"))
			if idx >= 0:
				_map_dropdown.select(idx)
				_on_map_selected(idx)
			break
