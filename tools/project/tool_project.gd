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

var _tex_albedo_thumb: TextureRect
var _tex_albedo_path: String
var _tex_normal_thumb: TextureRect
var _tex_normal_path: String
var _tex_orm_thumb: TextureRect
var _tex_orm_path: String
var _tex_emission_thumb: TextureRect
var _tex_emission_path: String

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

var _df_enabled: CheckBox
var _df_begin_spin: SpinBox
var _df_begin_slider: HSlider
var _df_len_spin: SpinBox
var _df_len_slider: HSlider

var _setting_slider := false
var _decal_nodes: Array[Decal] = []
var _selected_decal: Decal
var _preset_data = {}
var _multi_data: Array = []


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
	_pos_x.max_value = 99999; _pos_x.min_value = -99999
	_pos_y = SpinBox.new()
	_pos_y.max_value = 99999; _pos_y.min_value = -99999
	_pos_z = SpinBox.new()
	_pos_z.max_value = 99999; _pos_z.min_value = -99999
	pos_body.add_child(_make_vec3_row("Offset X/Y/Z:", _pos_x, _pos_y, _pos_z))
	_panel.add_child(_make_section("Position Offset", true, pos_body))

	var tex_body := VBoxContainer.new()
	tex_body.add_child(_build_texture_row("Albedo:", "_tex_albedo_thumb", "_tex_albedo_path", "_on_load_albedo", "_on_clear_albedo"))
	tex_body.add_child(_build_texture_row("Normal:", "_tex_normal_thumb", "_tex_normal_path", "_on_load_normal", "_on_clear_normal"))
	tex_body.add_child(_build_texture_row("ORM:", "_tex_orm_thumb", "_tex_orm_path", "_on_load_orm", "_on_clear_orm"))
	tex_body.add_child(_build_texture_row("Emission:", "_tex_emission_thumb", "_tex_emission_path", "_on_load_emission", "_on_clear_emission"))
	_panel.add_child(_make_section("Textures", true, tex_body))

	var param_body := VBoxContainer.new()
	_ee_spin = SpinBox.new()
	_ee_slider = HSlider.new()
	param_body.add_child(_make_slider_row("Emission Energy:", _ee_spin, _ee_slider, 0.0, 100.0, 0.01, 0.0))
	_ee_spin.value_changed.connect(_on_ee_changed)
	_ee_slider.value_changed.connect(_on_ee_slider)

	_am_spin = SpinBox.new()
	_am_slider = HSlider.new()
	param_body.add_child(_make_slider_row("Albedo Mix:", _am_spin, _am_slider, 0.0, 1.0, 0.01, 1.0))
	_am_spin.value_changed.connect(_on_am_changed)
	_am_slider.value_changed.connect(_on_am_slider)

	_modulate = ColorPickerButton.new()
	_modulate.color = Color.WHITE
	_modulate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mod_row := HBoxContainer.new()
	var mod_lbl := Label.new()
	mod_lbl.text = "Modulate:"
	mod_row.add_child(mod_lbl)
	mod_row.add_child(_modulate)
	param_body.add_child(mod_row)

	_nf_spin = SpinBox.new()
	_nf_slider = HSlider.new()
	param_body.add_child(_make_slider_row("Normal Fade:", _nf_spin, _nf_slider, 0.0, 1.0, 0.001, 0.0))
	_nf_spin.value_changed.connect(_on_nf_changed)
	_nf_slider.value_changed.connect(_on_nf_slider)
	_panel.add_child(_make_section("Parameters", true, param_body))

	var fade_body := VBoxContainer.new()
	_uf_spin = SpinBox.new()
	_uf_slider = HSlider.new()
	fade_body.add_child(_make_slider_row("Upper Fade:", _uf_spin, _uf_slider, 0.0, 10.0, 0.001, 0.3))
	_uf_spin.value_changed.connect(_on_uf_changed)
	_uf_slider.value_changed.connect(_on_uf_slider)

	_lf_spin = SpinBox.new()
	_lf_slider = HSlider.new()
	fade_body.add_child(_make_slider_row("Lower Fade:", _lf_spin, _lf_slider, 0.0, 10.0, 0.001, 0.3))
	_lf_spin.value_changed.connect(_on_lf_changed)
	_lf_slider.value_changed.connect(_on_lf_slider)
	_panel.add_child(_make_section("Vertical Fade", true, fade_body))

	var dist_body := VBoxContainer.new()
	_df_enabled = CheckBox.new()
	_df_enabled.text = "Enable"
	_df_enabled.toggled.connect(func(_t): _on_param_changed())
	dist_body.add_child(_df_enabled)

	_df_begin_spin = SpinBox.new()
	_df_begin_slider = HSlider.new()
	dist_body.add_child(_make_slider_row("Begin:", _df_begin_spin, _df_begin_slider, 0.0, 1000.0, 0.1, 10.0))
	_df_begin_spin.value_changed.connect(_on_df_begin_changed)
	_df_begin_slider.value_changed.connect(_on_df_begin_slider)

	_df_len_spin = SpinBox.new()
	_df_len_slider = HSlider.new()
	dist_body.add_child(_make_slider_row("Length:", _df_len_spin, _df_len_slider, 0.0, 1000.0, 0.1, 10.0))
	_df_len_spin.value_changed.connect(_on_df_len_changed)
	_df_len_slider.value_changed.connect(_on_df_len_slider)
	_panel.add_child(_make_section("Distance Fade", true, dist_body))

	return _panel


func _build_texture_row(label: String, _thumb_var: String, _path_var: String, load_fn: String, clear_fn: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(60, 0)
	row.add_child(lbl)

	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(48, 48)
	thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.modulate = Color(1, 1, 1, 0.3)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(36, 22)
	var clear_btn := Button.new()
	clear_btn.text = "X"
	clear_btn.custom_minimum_size = Vector2(22, 22)

	match label:
		"Albedo:":
			_tex_albedo_thumb = thumb
			load_btn.pressed.connect(_on_load_albedo)
			clear_btn.pressed.connect(_on_clear_albedo)
		"Normal:":
			_tex_normal_thumb = thumb
			load_btn.pressed.connect(_on_load_normal)
			clear_btn.pressed.connect(_on_clear_normal)
		"ORM:":
			_tex_orm_thumb = thumb
			load_btn.pressed.connect(_on_load_orm)
			clear_btn.pressed.connect(_on_clear_orm)
		"Emission:":
			_tex_emission_thumb = thumb
			load_btn.pressed.connect(_on_load_emission)
			clear_btn.pressed.connect(_on_clear_emission)

	row.add_child(thumb)
	var btn_col := VBoxContainer.new()
	btn_col.add_child(load_btn)
	btn_col.add_child(clear_btn)
	row.add_child(btn_col)
	return row


func _set_texture_thumb(thumb: TextureRect, path: String, value: Texture2D) -> void:
	thumb.texture = value
	thumb.modulate = Color(1, 1, 1, 0.3 if not value else 1.0)


func _set_texture(varname: String, path: String) -> void:
	match varname:
		"_tex_albedo_path": _tex_albedo_path = path
		"_tex_normal_path": _tex_normal_path = path
		"_tex_orm_path": _tex_orm_path = path
		"_tex_emission_path": _tex_emission_path = path

	var tex: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path) as Texture2D

	match varname:
		"_tex_albedo_path": _set_texture_thumb(_tex_albedo_thumb, path, tex)
		"_tex_normal_path": _set_texture_thumb(_tex_normal_thumb, path, tex)
		"_tex_orm_path": _set_texture_thumb(_tex_orm_thumb, path, tex)
		"_tex_emission_path": _set_texture_thumb(_tex_emission_thumb, path, tex)

	if _selected_decal and is_instance_valid(_selected_decal):
		_update_decal_from_ui(_selected_decal)


func _open_texture_dialog(callback: Callable) -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.add_filter("*.jpg,*.png,*.webp,*.exr,*.hdr", "Textures")
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_selected.connect(callback)
	fd.popup_centered(Vector2i(600, 400))
	_panel.add_child(fd)


func _on_load_albedo() -> void:
	_open_texture_dialog(func(p): _set_texture("_tex_albedo_path", p))


func _on_clear_albedo() -> void:
	_set_texture("_tex_albedo_path", "")


func _on_load_normal() -> void:
	_open_texture_dialog(func(p): _set_texture("_tex_normal_path", p))


func _on_clear_normal() -> void:
	_set_texture("_tex_normal_path", "")


func _on_load_orm() -> void:
	_open_texture_dialog(func(p): _set_texture("_tex_orm_path", p))


func _on_clear_orm() -> void:
	_set_texture("_tex_orm_path", "")


func _on_load_emission() -> void:
	_open_texture_dialog(func(p): _set_texture("_tex_emission_path", p))


func _on_clear_emission() -> void:
	_set_texture("_tex_emission_path", "")


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


func _on_ee_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_ee_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_ee_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_ee_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_am_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_am_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_am_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_am_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_nf_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_nf_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_nf_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_nf_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_uf_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_uf_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_uf_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_uf_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_lf_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_lf_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_lf_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_lf_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_df_begin_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_df_begin_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_df_begin_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_df_begin_spin.value = v
	_setting_slider = false
	_on_param_changed()


func _on_df_len_changed(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_df_len_slider.value = v
	_setting_slider = false
	_on_param_changed()


func _on_df_len_slider(v: float) -> void:
	if _setting_slider: return
	_setting_slider = true
	_df_len_spin.value = v
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
	_pos_x.value = 0.0; _pos_y.value = 0.0; _pos_z.value = 0.0

	_set_texture("_tex_albedo_path", data.get("tex", ""))
	_set_texture("_tex_normal_path", "")
	_set_texture("_tex_orm_path", "")
	_set_texture("_tex_emission_path", data.get("tex", ""))

	_setting_slider = true
	_set_spin_slider(_ee_spin, _ee_slider, data.get("ee", 0.0))
	_set_spin_slider(_am_spin, _am_slider, data.get("am", 1.0))
	_set_spin_slider(_nf_spin, _nf_slider, data.get("nf", 0.0))
	_set_spin_slider(_uf_spin, _uf_slider, data.get("uf", 0.3))
	_set_spin_slider(_lf_spin, _lf_slider, data.get("lf", 0.3))
	_set_spin_slider(_df_begin_spin, _df_begin_slider, data.get("dfb", 10.0))
	_set_spin_slider(_df_len_spin, _df_len_slider, data.get("dfl", 10.0))
	_df_enabled.button_pressed = data.get("dfe", false)
	_setting_slider = false


func _read_decal_to_ui(decal: Decal) -> void:
	if not decal or not is_instance_valid(decal):
		return
	_size_x.value = decal.size.x
	_size_y.value = decal.size.y
	_size_z.value = decal.size.z

	var base_pos := _preset_data.get("pos", Vector3.ZERO) if not (_preset_data is Array) else Vector3.ZERO
	_pos_x.value = decal.position.x - base_pos.x
	_pos_y.value = decal.position.y - base_pos.y
	_pos_z.value = decal.position.z - base_pos.z

	_setting_slider = true
	_set_spin_slider(_ee_spin, _ee_slider, decal.emission_energy)
	_set_spin_slider(_am_spin, _am_slider, decal.albedo_mix)
	_set_spin_slider(_nf_spin, _nf_slider, decal.normal_fade)
	_set_spin_slider(_uf_spin, _uf_slider, decal.upper_fade)
	_set_spin_slider(_lf_spin, _lf_slider, decal.lower_fade)
	_set_spin_slider(_df_begin_spin, _df_begin_slider, decal.distance_fade_begin)
	_set_spin_slider(_df_len_spin, _df_len_slider, decal.distance_fade_length)
	_df_enabled.button_pressed = decal.distance_fade_enabled
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
	for d in _decal_nodes:
		if is_instance_valid(d):
			d.queue_free()
	_decal_nodes = []
	_selected_decal = null


func _on_param_changed() -> void:
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

	decal.texture_albedo = _load_texture_or_null(_tex_albedo_path)
	decal.texture_normal = _load_texture_or_null(_tex_normal_path)
	decal.texture_orm = _load_texture_or_null(_tex_orm_path)
	decal.texture_emission = _load_texture_or_null(_tex_emission_path)

	decal.emission_energy = _ee_spin.value
	decal.albedo_mix = _am_spin.value
	decal.modulate = _modulate.color
	decal.normal_fade = _nf_spin.value
	decal.upper_fade = _uf_spin.value
	decal.lower_fade = _lf_spin.value
	decal.distance_fade_enabled = _df_enabled.button_pressed
	decal.distance_fade_begin = _df_begin_spin.value
	decal.distance_fade_length = _df_len_spin.value


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
