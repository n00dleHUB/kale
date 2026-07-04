@tool
extends KaleBase

const Presets = preload("res://addons/Kale/tools/project/project_data.gd")

var _panel: VBoxContainer
var _map_dropdown: OptionButton
var _sub_dropdown: OptionButton
var _sub_row: HBoxContainer
var _spawn_btn: Button
var _remove_btn: Button

var _size_x: SpinBox
var _size_y: SpinBox
var _size_z: SpinBox

var _tex_albedo_path: LineEdit
var _tex_normal_path: LineEdit
var _tex_orm_path: LineEdit
var _tex_emission_path: LineEdit

var _ee_spin: SpinBox
var _ee_slider: HSlider
var _am_spin: SpinBox
var _am_slider: HSlider
var _nf_spin: SpinBox
var _nf_slider: HSlider
var _uf_spin: SpinBox
var _uf_slider: HSlider
var _lf_spin: SpinBox
var _lf_slider: HSlider
var _modulate: ColorPickerButton

var _setting_slider := false
var _decal_nodes: Array[Decal] = []
var _selected_decal: Decal
var _preset_data = {}
var _multi_data: Array = []

const DECAL_LAYER_BIT := 1
var _target_paths: Array[NodePath] = [NodePath("Static")]
var _targets_container: VBoxContainer


func get_tool_name() -> String:
	return "Map Project"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(380, 0)

	var pres_lbl := Label.new()
	pres_lbl.text = "Map Preset:"
	_panel.add_child(pres_lbl)

	_map_dropdown = OptionButton.new()
	_map_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var names := Presets.get_names()
	for i in names.size():
		_map_dropdown.add_item(names[i])
		if names[i] == "MP_Dumbo":
			_map_dropdown.select(i)
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
	var _select_btn := Button.new()
	_select_btn.text = "Select in Inspector"
	_select_btn.pressed.connect(_on_select_in_inspector)
	btn_row.add_child(_select_btn)
	_panel.add_child(btn_row)

	# ── Decal Parameters (collapsible) ──
	var decal_body := VBoxContainer.new()

	_size_x = SpinBox.new()
	_size_x.max_value = 99999
	_size_y = SpinBox.new()
	_size_y.max_value = 99999
	_size_z = SpinBox.new()
	_size_z.max_value = 99999
	decal_body.add_child(_make_vec3_row("Size X/Y/Z:", _size_x, _size_y, _size_z))

	decal_body.add_child(HSeparator.new())

	decal_body.add_child(_build_texture_row("Albedo:"))
	decal_body.add_child(_build_texture_row("Normal:"))
	decal_body.add_child(_build_texture_row("ORM:"))
	decal_body.add_child(_build_texture_row("Emission:"))

	decal_body.add_child(HSeparator.new())

	_ee_spin = SpinBox.new()
	_ee_slider = HSlider.new()
	decal_body.add_child(_make_slider_row("Emission Energy:", _ee_spin, _ee_slider, 0.0, 100.0, 0.01, 0.0))
	_ee_spin.value_changed.connect(_sync_slider.bind(_ee_spin, _ee_slider))
	_ee_slider.value_changed.connect(_sync_slider.bind(_ee_spin, _ee_slider))

	_am_spin = SpinBox.new()
	_am_slider = HSlider.new()
	decal_body.add_child(_make_slider_row("Albedo Mix:", _am_spin, _am_slider, 0.0, 1.0, 0.01, 1.0))
	_am_spin.value_changed.connect(_sync_slider.bind(_am_spin, _am_slider))
	_am_slider.value_changed.connect(_sync_slider.bind(_am_spin, _am_slider))

	_modulate = ColorPickerButton.new()
	_modulate.color = Color.WHITE
	_modulate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modulate.color_changed.connect(func(_c): _on_param_changed())
	var mod_row := HBoxContainer.new()
	var mod_lbl := Label.new()
	mod_lbl.text = "Modulate:"
	mod_row.add_child(mod_lbl)
	mod_row.add_child(_modulate)
	decal_body.add_child(mod_row)

	_nf_spin = SpinBox.new()
	_nf_slider = HSlider.new()
	decal_body.add_child(_make_slider_row("Normal Fade:", _nf_spin, _nf_slider, 0.0, 1.0, 0.001, 0.0))
	_nf_spin.value_changed.connect(_sync_slider.bind(_nf_spin, _nf_slider))
	_nf_slider.value_changed.connect(_sync_slider.bind(_nf_spin, _nf_slider))

	decal_body.add_child(HSeparator.new())

	_uf_spin = SpinBox.new()
	_uf_slider = HSlider.new()
	decal_body.add_child(_make_slider_row("Upper Fade:", _uf_spin, _uf_slider, 0.0, 10.0, 0.001, 0.3))
	_uf_spin.value_changed.connect(_sync_slider.bind(_uf_spin, _uf_slider))
	_uf_slider.value_changed.connect(_sync_slider.bind(_uf_spin, _uf_slider))

	_lf_spin = SpinBox.new()
	_lf_slider = HSlider.new()
	decal_body.add_child(_make_slider_row("Lower Fade:", _lf_spin, _lf_slider, 0.0, 10.0, 0.001, 0.3))
	_lf_spin.value_changed.connect(_sync_slider.bind(_lf_spin, _lf_slider))
	_lf_slider.value_changed.connect(_sync_slider.bind(_lf_spin, _lf_slider))

	_panel.add_child(_make_section("Decal Parameters", true, decal_body))

	# ── Projection Targets (collapsible) ──
	var tgt_body := VBoxContainer.new()

	var tgt_info := Label.new()
	tgt_info.text = "Select nodes in the scene tree, then click Select"
	tgt_info.add_theme_font_size_override("font_size", 10)
	tgt_body.add_child(tgt_info)

	_targets_container = VBoxContainer.new()
	tgt_body.add_child(_targets_container)

	var tgt_add := Button.new()
	tgt_add.text = "Add Target"
	tgt_add.pressed.connect(_on_add_target_row)
	tgt_body.add_child(tgt_add)

	_panel.add_child(_make_section("Projection Targets", true, tgt_body))

	_refresh_target_rows()

	_on_map_selected(_map_dropdown.selected)

	return _panel


func _build_texture_row(label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(60, 0)
	row.add_child(lbl)

	var path_edit := LineEdit.new()
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_open_texture_dialog.bind(path_edit))
	var clear_btn := Button.new()
	clear_btn.text = "X"
	clear_btn.pressed.connect(func(): path_edit.text = ""; _on_param_changed())

	match label:
		"Albedo:":
			_tex_albedo_path = path_edit
		"Normal:":
			_tex_normal_path = path_edit
		"ORM:":
			_tex_orm_path = path_edit
		"Emission:":
			_tex_emission_path = path_edit

	row.add_child(path_edit)
	row.add_child(load_btn)
	row.add_child(clear_btn)
	return row


func _open_texture_dialog(path_edit: LineEdit) -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.add_filter("*.jpg,*.png,*.webp,*.exr,*.hdr", "Textures")
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_selected.connect(func(p): path_edit.text = p; _on_param_changed())
	fd.popup_centered(Vector2i(600, 400))
	_panel.add_child(fd)


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


func _make_slider_row(label: String, spin: SpinBox, slider: HSlider, min_v: float, max_v: float, step_v: float, default_v: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl)

	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = step_v
	spin.value = default_v
	spin.custom_minimum_size = Vector2(55, 0)
	row.add_child(spin)

	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = default_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.scrollable = false
	row.add_child(slider)

	return row


func _make_vec3_row(label: String, sx: SpinBox, sy: SpinBox, sz: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl)
	for spin in [sx, sy, sz]:
		spin.custom_minimum_size = Vector2(60, 0)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(_on_param_changed)
		row.add_child(spin)
	return row


func _set_spin_slider(spin: SpinBox, slider: HSlider, v: float) -> void:
	spin.value = v
	slider.value = v


func _sync_slider(v: float, spin: SpinBox, slider: HSlider) -> void:
	if _setting_slider:
		return
	_setting_slider = true
	spin.value = v
	slider.value = v
	_setting_slider = false
	_on_param_changed()


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
			_sub_dropdown.add_item("Decal " + str(_sub_dropdown.item_count + 1))
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

	_tex_albedo_path.text = data.get("tex", "")
	_tex_normal_path.text = ""
	_tex_orm_path.text = ""
	_tex_emission_path.text = data.get("tex", "")

	_setting_slider = true
	_set_spin_slider(_ee_spin, _ee_slider, data.get("ee", 0.0))
	_set_spin_slider(_am_spin, _am_slider, data.get("am", 1.0))
	_set_spin_slider(_nf_spin, _nf_slider, data.get("nf", 0.0))
	_set_spin_slider(_uf_spin, _uf_slider, data.get("uf", 0.3))
	_set_spin_slider(_lf_spin, _lf_slider, data.get("lf", 0.3))
	_setting_slider = false


func _read_decal_to_ui(decal: Decal) -> void:
	if not decal or not is_instance_valid(decal):
		return
	_size_x.value = decal.size.x
	_size_y.value = decal.size.y
	_size_z.value = decal.size.z

	_setting_slider = true
	_set_spin_slider(_ee_spin, _ee_slider, decal.emission_energy)
	_set_spin_slider(_am_spin, _am_slider, decal.albedo_mix)
	_set_spin_slider(_nf_spin, _nf_slider, decal.normal_fade)
	_set_spin_slider(_uf_spin, _uf_slider, decal.upper_fade)
	_set_spin_slider(_lf_spin, _lf_slider, decal.lower_fade)
	_setting_slider = false

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

	_on_remove()

	if _preset_data is Array:
		var i := 0
		for entry in _preset_data:
			_spawn_single_decal(root, map_name + "_" + str(i), entry, map_name)
			i += 1
	else:
		_spawn_single_decal(root, map_name, _preset_data, map_name)

	_assign_target_layers(root)

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
	decal.cull_mask = 1 << DECAL_LAYER_BIT

	var d: Dictionary = data if data is Dictionary else {}
	decal.position = d.get("pos", Vector3.ZERO)
	decal.size = d.get("size", Vector3.ONE)

	var tex_path: String = d.get("tex", "")
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		decal.texture_albedo = load(tex_path)
		decal.texture_emission = load(tex_path)

	decal.emission_energy = d.get("ee", 0.0)
	decal.albedo_mix = d.get("am", 1.0)
	decal.normal_fade = d.get("nf", 0.0)
	decal.upper_fade = d.get("uf", 0.3)
	decal.lower_fade = d.get("lf", 0.3)
	decal.distance_fade_enabled = d.get("dfe", false)
	decal.distance_fade_begin = d.get("dfb", 10.0)
	decal.distance_fade_length = d.get("dfl", 10.0)

	root.add_child(decal, true)
	decal.set_owner(root)


func _on_remove() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root:
		for child in root.find_children("*", "Decal", true, false):
			if child.has_meta("map_project"):
				child.queue_free()
		_restore_target_layers(root)
	_decal_nodes = []
	_selected_decal = null


func _refresh_target_rows() -> void:
	for c in _targets_container.get_children():
		c.queue_free()
	for i in _target_paths.size():
		var row := HBoxContainer.new()
		var path_edit := LineEdit.new()
		path_edit.text = str(_target_paths[i])
		path_edit.editable = false
		path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		path_edit.placeholder_text = "Select a node in the scene tree"
		path_edit.tooltip_text = "Select a node in the scene tree, then click Select"
		row.add_child(path_edit)

		var sel_btn := Button.new()
		sel_btn.text = "Select"
		sel_btn.pressed.connect(_on_select_target.bind(path_edit, i))
		row.add_child(sel_btn)

		var remove_btn := Button.new()
		remove_btn.text = "X"
		remove_btn.pressed.connect(_on_remove_target_row.bind(i))
		row.add_child(remove_btn)

		_targets_container.add_child(row)


func _on_select_target(path_edit: LineEdit, idx: int) -> void:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty():
		return
	var node := selected[0]
	var root := EditorInterface.get_edited_scene_root()
	if not root or not root.is_ancestor_of(node):
		return
	var path := root.get_path_to(node)
	_target_paths[idx] = path
	path_edit.text = str(path)


func _on_add_target_row() -> void:
	_target_paths.append(NodePath())
	_refresh_target_rows()


func _on_remove_target_row(idx: int) -> void:
	if _target_paths.size() <= 1:
		return
	_target_paths.remove_at(idx)
	_refresh_target_rows()


func _assign_target_layers(root: Node) -> void:
	var layer_mask := 1 << DECAL_LAYER_BIT
	for path in _target_paths:
		var target := root.get_node_or_null(path)
		if not target:
			continue
		for gi in target.find_children("*", "GeometryInstance3D", true, false):
			var inst := gi as GeometryInstance3D
			if not inst:
				continue
			var orig: int = inst.get_meta("_kale_orig_layers", -1)
			if orig == -1:
				inst.set_meta("_kale_orig_layers", inst.layers)
			inst.layers |= layer_mask


func _restore_target_layers(root: Node) -> void:
	for path in _target_paths:
		var target := root.get_node_or_null(path)
		if not target:
			continue
		for gi in target.find_children("*", "GeometryInstance3D", true, false):
			var inst := gi as GeometryInstance3D
			if not inst or not inst.has_meta("_kale_orig_layers"):
				continue
			inst.layers = inst.get_meta("_kale_orig_layers")
			inst.remove_meta("_kale_orig_layers")


func _on_select_in_inspector() -> void:
	if _selected_decal and is_instance_valid(_selected_decal):
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(_selected_decal)
		EditorInterface.edit_node(_selected_decal)
		call_deferred("_focus_inspector_dock")


func _focus_inspector_dock() -> void:
	var editor := EditorInterface.get_base_control()
	if not editor:
		return
	for tc in editor.find_children("*", "TabContainer", true, false):
		for i in tc.get_tab_count():
			if tc.get_tab_title(i) == "Inspector":
				tc.current_tab = i
				return


func _on_param_changed(_v: float = 0.0) -> void:
	if _selected_decal and is_instance_valid(_selected_decal):
		_update_decal_from_ui(_selected_decal)


func _load_texture_or_null(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _update_decal_from_ui(decal: Decal) -> void:
	if not decal or not is_instance_valid(decal):
		return

	decal.size = Vector3(_size_x.value, _size_y.value, _size_z.value)

	decal.texture_albedo = _load_texture_or_null(_tex_albedo_path.text)
	decal.texture_normal = _load_texture_or_null(_tex_normal_path.text)
	decal.texture_orm = _load_texture_or_null(_tex_orm_path.text)
	decal.texture_emission = _load_texture_or_null(_tex_emission_path.text)

	decal.emission_energy = _ee_spin.value
	decal.albedo_mix = _am_spin.value
	decal.modulate = _modulate.color
	decal.normal_fade = _nf_spin.value
	decal.upper_fade = _uf_spin.value
	decal.lower_fade = _lf_spin.value


func on_editor_scene_changed(_root: Node) -> void:
	_decal_nodes = []
	_selected_decal = null
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	for child in root.find_children("*", "Decal", true, false):
		if child.has_meta("map_project"):
			var map_name: String = child.get_meta("map_project")
			var idx := -1
			for i in _map_dropdown.item_count:
				if _map_dropdown.get_item_text(i) == map_name:
					idx = i
					break
			if idx >= 0:
				_map_dropdown.select(idx)
				_on_map_selected(idx)
				break
