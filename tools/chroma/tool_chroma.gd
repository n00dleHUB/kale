@tool
extends KaleBase

const Materials = preload("res://addons/Kale/tools/chroma/chroma_materials.gd")
const Cache = preload("res://addons/Kale/tools/chroma/chroma_cache.gd")

const UV_SPACE_LOCAL := 0
const UV_SPACE_WORLD := 1

const DEFAULT_COLORS := [
	Color8(210, 130, 50), Color8(190, 150, 60), Color8(120, 140, 60),
	Color8(90, 140, 90), Color8(70, 130, 120), Color8(195, 85, 70),
	Color8(80, 120, 150), Color8(120, 100, 150), Color8(180, 150, 100),
	Color8(130, 120, 115), Color8(220, 220, 215), Color8(50, 50, 50)
]

var _panel: VBoxContainer
var _preset: OptionButton
var _color_picker: ColorPickerButton
var _swatch_row1: HBoxContainer
var _swatch_row2: HBoxContainer
var _custom_tex_path: LineEdit
var _texture_list: OptionButton
var _file_dialog: FileDialog

var _spec_spin: SpinBox
var _spec_slider: HSlider
var _rough_spin: SpinBox
var _rough_slider: HSlider

var _opacity_spin: SpinBox
var _opacity_slider: HSlider

var _double_sided: CheckBox
var _uv_mode: OptionButton
var _tiling_x_spin: SpinBox
var _tiling_x_slider: HSlider
var _tiling_y_spin: SpinBox
var _tiling_y_slider: HSlider
var _tiling_scale_spin: SpinBox
var _tiling_scale_slider: HSlider
var _tiling_x_row: HBoxContainer
var _tiling_y_row: HBoxContainer
var _uv_space: OptionButton
var _space_row: HBoxContainer
var _pattern: OptionButton
var _pattern_row: HBoxContainer
var _random_mode: OptionButton

var _fix_tiling: CheckBox
var _status: Label
var _scene_root: Node

var _setting_slider := false
static var _random_seed := 0


func get_tool_name() -> String:
	return "Chroma"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(380, 0)

	var preset_lbl := Label.new()
	preset_lbl.text = "Preset:"
	_panel.add_child(preset_lbl)

	_preset = OptionButton.new()
	_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for p in Materials.get_preset_names():
		_preset.add_item(p)
	_preset.item_selected.connect(_on_preset_changed)
	_panel.add_child(_preset)

	_pattern_row = HBoxContainer.new()
	var pat_lbl := Label.new()
	pat_lbl.text = "Pattern:"
	_pattern_row.add_child(pat_lbl)
	_pattern = OptionButton.new()
	for p in Materials.PATTERN_NAMES:
		_pattern.add_item(p)
	_pattern.selected = 0
	_pattern.item_selected.connect(_on_pattern_changed)
	_pattern_row.add_child(_pattern)
	_pattern_row.visible = true

	var color_body := VBoxContainer.new()
	color_body.add_child(_build_color_row())
	color_body.add_child(_pattern_row)
	_panel.add_child(_make_section("Diffuse", false, color_body))

	var shader_body := VBoxContainer.new()

	shader_body.add_child(_build_texture_row())
	shader_body.add_child(_build_texture_list_row())

	_spec_spin = SpinBox.new()
	_spec_slider = HSlider.new()
	shader_body.add_child(_make_slider_row("Specular", _spec_spin, _spec_slider, 0.0, 1.0, 0.01, 0.5))
	_spec_spin.value_changed.connect(_on_spec_changed)
	_spec_slider.value_changed.connect(_on_spec_slider)

	_rough_spin = SpinBox.new()
	_rough_slider = HSlider.new()
	shader_body.add_child(_make_slider_row("Roughness", _rough_spin, _rough_slider, 0.0, 1.0, 0.01, 0.5))
	_rough_spin.value_changed.connect(_on_rough_changed)
	_rough_slider.value_changed.connect(_on_rough_slider)

	_opacity_spin = SpinBox.new()
	_opacity_slider = HSlider.new()
	shader_body.add_child(_make_slider_row("Opacity", _opacity_spin, _opacity_slider, 0.0, 1.0, 0.01, 1.0))
	_opacity_spin.value_changed.connect(_on_opacity_changed)
	_opacity_slider.value_changed.connect(_on_opacity_slider)

	_double_sided = CheckBox.new()
	_double_sided.text = "Double-sided"
	_double_sided.button_pressed = true
	_double_sided.toggled.connect(func(_on): _live_update_selection())
	shader_body.add_child(_double_sided)

	_panel.add_child(_make_section("Shader", true, shader_body))

	# ── UV section (collapsed) ──
	var uv_body := VBoxContainer.new()

	var mode_row := HBoxContainer.new()
	var mode_lbl := Label.new()
	mode_lbl.text = "UV Mode:"
	mode_row.add_child(mode_lbl)
	_uv_mode = OptionButton.new()
	_uv_mode.add_item("Projected")
	_uv_mode.add_item("Triplanar")
	_uv_mode.selected = 0
	_uv_mode.item_selected.connect(_on_uv_mode_changed)
	mode_row.add_child(_uv_mode)
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	uv_body.add_child(mode_row)

	_space_row = HBoxContainer.new()
	var space_lbl := Label.new()
	space_lbl.text = "Space:"
	_space_row.add_child(space_lbl)
	_uv_space = OptionButton.new()
	_uv_space.add_item("Local", UV_SPACE_LOCAL)
	_uv_space.add_item("World", UV_SPACE_WORLD)
	_uv_space.item_selected.connect(func(_i): _live_update_selection())
	_space_row.add_child(_uv_space)
	uv_body.add_child(_space_row)

	_tiling_scale_spin = SpinBox.new()
	_tiling_scale_slider = HSlider.new()
	uv_body.add_child(_make_slider_row("Tiling Scale", _tiling_scale_spin, _tiling_scale_slider, 0.01, 4.0, 0.01, 1.0))
	_tiling_scale_spin.max_value = 50.0
	_tiling_scale_spin.value_changed.connect(_on_tiling_scale_changed)
	_tiling_scale_slider.value_changed.connect(_on_tiling_scale_slider)

	_tiling_x_spin = SpinBox.new()
	_tiling_x_slider = HSlider.new()
	_tiling_x_row = _make_slider_row("Tiling X", _tiling_x_spin, _tiling_x_slider, 0.01, 2.0, 0.01, 1.0)
	_tiling_x_spin.max_value = 50.0
	uv_body.add_child(_tiling_x_row)
	_tiling_x_spin.value_changed.connect(_on_tiling_x_changed)
	_tiling_x_slider.value_changed.connect(_on_tiling_x_slider)

	_tiling_y_spin = SpinBox.new()
	_tiling_y_slider = HSlider.new()
	_tiling_y_row = _make_slider_row("Tiling Y", _tiling_y_spin, _tiling_y_slider, 0.01, 2.0, 0.01, 1.0)
	_tiling_y_spin.max_value = 50.0
	uv_body.add_child(_tiling_y_row)
	_tiling_y_spin.value_changed.connect(_on_tiling_y_changed)
	_tiling_y_slider.value_changed.connect(_on_tiling_y_slider)

	_fix_tiling = CheckBox.new()
	_fix_tiling.text = "Fix Tiling"
	_fix_tiling.button_pressed = false
	_fix_tiling.toggled.connect(func(_on): _live_update_selection())
	uv_body.add_child(_fix_tiling)

	_panel.add_child(_make_section("UV", true, uv_body))

	# ── Actions section ──
	var actions_header := _make_section_label("Actions")
	_panel.add_child(actions_header)

	var row1 := HBoxContainer.new()
	var apply_sel := Button.new()
	apply_sel.text = "Apply Selected"
	apply_sel.pressed.connect(_apply_selected)
	row1.add_child(apply_sel)

	var clear_sel := Button.new()
	clear_sel.text = "Clear Selected"
	clear_sel.pressed.connect(_clear_selected)
	row1.add_child(clear_sel)
	_panel.add_child(row1)

	var row2 := HBoxContainer.new()
	var apply_all := Button.new()
	apply_all.text = "Apply All"
	apply_all.pressed.connect(_apply_all)
	row2.add_child(apply_all)

	var clear_all := Button.new()
	clear_all.text = "Clear All"
	clear_all.pressed.connect(_clear_all)
	row2.add_child(clear_all)
	_panel.add_child(row2)

	var row3 := HBoxContainer.new()
	var clear_cache := Button.new()
	clear_cache.text = "Clear Cache"
	clear_cache.pressed.connect(_clear_cache)
	row3.add_child(clear_cache)

	var open_cache := Button.new()
	open_cache.text = "Open Cache"
	open_cache.pressed.connect(_open_cache)
	row3.add_child(open_cache)
	_panel.add_child(row3)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.add_filter("*.png,*.jpg,*.webp,*.exr", "Textures")
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_selected.connect(_on_texture_file_selected)
	_panel.add_child(_file_dialog)

	_status = Label.new()
	_status.text = ""
	_panel.add_child(_status)

	_scan_textures()
	_update_pattern_visibility()

	return _panel


func _build_color_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 56)

	_color_picker = ColorPickerButton.new()
	_color_picker.color = Color(0.75, 0.75, 0.75, 1.0)
	_color_picker.edit_alpha = true
	_color_picker.custom_minimum_size = Vector2(56, 48)
	_color_picker.color_changed.connect(_on_color_changed)
	row.add_child(_color_picker)

	var swatch_col := VBoxContainer.new()
	swatch_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_swatch_row1 = HBoxContainer.new()
	_swatch_row2 = HBoxContainer.new()
	swatch_col.add_child(_swatch_row1)
	swatch_col.add_child(_swatch_row2)
	_rebuild_swatches()

	row.add_child(swatch_col)

	_random_mode = OptionButton.new()
	_random_mode.add_item("Same color")
	_random_mode.add_item("Per asset")
	_random_mode.add_item("Per object")
	_random_mode.selected = 0
	_random_mode.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(_random_mode)

	return row


func _rebuild_swatches() -> void:
	for c in _swatch_row1.get_children().duplicate():
		_swatch_row1.remove_child(c)
		c.queue_free()
	for c in _swatch_row2.get_children().duplicate():
		_swatch_row2.remove_child(c)
		c.queue_free()

	var half := DEFAULT_COLORS.size() / 2
	for i in range(DEFAULT_COLORS.size()):
		var col: Color = DEFAULT_COLORS[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(24, 20)
		btn.icon = _make_swatch_icon(col)
		btn.tooltip_text = "#%02X%02X%02X" % [col.r8, col.g8, col.b8]
		btn.pressed.connect(_on_swatch_pressed.bind(col))

		if i < half:
			_swatch_row1.add_child(btn)
		else:
			_swatch_row2.add_child(btn)


func _make_swatch_icon(col: Color) -> Texture2D:
	var sz := 22
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in range(sz):
		for x in range(sz):
			var border := x == 0 or y == 0 or x == sz - 1 or y == sz - 1
			img.set_pixel(x, y, Color.BLACK if border else col)
	return ImageTexture.create_from_image(img)


func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	return lbl


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


func _build_texture_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Tex:"
	row.add_child(lbl)

	_custom_tex_path = LineEdit.new()
	_custom_tex_path.placeholder_text = "custom texture path..."
	_custom_tex_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_custom_tex_path.editable = false
	row.add_child(_custom_tex_path)

	var browse := Button.new()
	browse.text = "Browse"
	browse.pressed.connect(_on_browse_texture)
	row.add_child(browse)

	var clear_tex := Button.new()
	clear_tex.text = "X"
	clear_tex.pressed.connect(_on_clear_texture)
	row.add_child(clear_tex)

	return row


func _build_texture_list_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Texture:"
	row.add_child(lbl)

	_texture_list = OptionButton.new()
	_texture_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texture_list.item_selected.connect(_on_texture_list_changed)
	row.add_child(_texture_list)
	return row


func _scan_textures() -> void:
	_texture_list.clear()
	_texture_list.add_item("(None)")
	var dir := DirAccess.open("res://addons/Kale/textures/")
	if not dir:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.get_extension().to_lower() == "png":
			_texture_list.add_item(fname)
		fname = dir.get_next()
	dir.list_dir_end()


func _on_texture_list_changed(idx: int) -> void:
	if idx == 0:
		_custom_tex_path.text = ""
	else:
		var fname := _texture_list.get_item_text(idx)
		_custom_tex_path.text = "res://addons/Kale/textures/" + fname
	_update_pattern_visibility()
	_live_update_selection()


func _update_texture_list_selection() -> void:
	var path: String = _custom_tex_path.text
	if path.is_empty() or not path.begins_with("res://addons/Kale/textures/"):
		_texture_list.select(0)
		return
	var fname := path.trim_prefix("res://addons/Kale/textures/")
	for i in range(1, _texture_list.item_count):
		if _texture_list.get_item_text(i) == fname:
			_texture_list.select(i)
			return
	_texture_list.select(0)


func _make_slider_row(label: String, spin: SpinBox, slider: HSlider, min_v: float, max_v: float, step_v: float, default_v: float) -> HBoxContainer:
	var row := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(70, 0)
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


func _on_swatch_pressed(col: Color) -> void:
	_color_picker.color = col
	var nodes := _get_selected_mesh_nodes()
	if not nodes.is_empty():
		var mat := _build_current_material()
		for n in nodes:
			_apply_node(n, mat)
		_save_cache()
		EditorInterface.mark_scene_as_unsaved()


func _on_color_changed(_c: Color) -> void:
	var nodes := _get_selected_mesh_nodes()
	if not nodes.is_empty():
		var mat := _build_current_material()
		for n in nodes:
			_apply_node(n, mat)
		_save_cache()
		EditorInterface.mark_scene_as_unsaved()


func _on_preset_changed(_idx: int) -> void:
	var name := _preset.get_item_text(_preset.selected)
	var defaults := Materials.PRESETS.get(name, {})
	_set_slider_values(defaults)
	_set_uv_values(defaults)
	if defaults.has("color"):
		_color_picker.color = defaults["color"] as Color

	var tex_path: String = defaults.get("texture", "")
	_custom_tex_path.text = tex_path
	_update_texture_list_selection()

	_update_pattern_visibility()

	_live_update_selection()


func _set_slider_values(vals: Dictionary) -> void:
	_setting_slider = true
	_set_spin_slider(_spec_spin, _spec_slider, vals.get("spec", 0.5))
	_set_spin_slider(_rough_spin, _rough_slider, vals.get("rough", 0.5))
	_set_spin_slider(_opacity_spin, _opacity_slider, vals.get("opacity", 1.0))
	_setting_slider = false


func _set_spin_slider(spin: SpinBox, slider: HSlider, val: float) -> void:
	spin.value = val
	slider.value = val


func _set_uv_values(_vals: Dictionary) -> void:
	_set_spin_slider(_tiling_scale_spin, _tiling_scale_slider, 1.0)
	_set_spin_slider(_tiling_x_spin, _tiling_x_slider, 1.0)
	_set_spin_slider(_tiling_y_spin, _tiling_y_slider, 1.0)


func _on_uv_mode_changed(_idx: int) -> void:
	var mode := _uv_mode.get_item_text(_uv_mode.selected)
	var is_triplanar := mode == "Triplanar"
	_tiling_x_row.visible = not is_triplanar
	_tiling_y_row.visible = not is_triplanar

	_tiling_scale_spin.value = 1.0
	_tiling_scale_slider.value = 1.0
	_tiling_x_spin.value = 1.0
	_tiling_x_slider.value = 1.0
	_tiling_y_spin.value = 1.0
	_tiling_y_slider.value = 1.0

	_live_update_selection()


func _on_pattern_changed(_idx: int) -> void:
	_live_update_selection()


func _on_spec_changed(v: float) -> void:
	if _setting_slider: return
	_spec_slider.value = v
	_live_update_selection()

func _on_spec_slider(v: float) -> void:
	if _setting_slider: return
	_spec_spin.value = v
	_live_update_selection()

func _on_rough_changed(v: float) -> void:
	if _setting_slider: return
	_rough_slider.value = v
	_live_update_selection()

func _on_rough_slider(v: float) -> void:
	if _setting_slider: return
	_rough_spin.value = v
	_live_update_selection()


func _on_opacity_changed(v: float) -> void:
	if _setting_slider: return
	_opacity_slider.value = v
	_live_update_selection()

func _on_opacity_slider(v: float) -> void:
	if _setting_slider: return
	_opacity_spin.value = v
	_live_update_selection()

func _on_tiling_x_changed(v: float) -> void:
	if _setting_slider: return
	if v <= _tiling_x_slider.max_value:
		_tiling_x_slider.value = v
	_live_update_selection()

func _on_tiling_x_slider(v: float) -> void:
	if _setting_slider: return
	_tiling_x_spin.value = v
	_live_update_selection()

func _on_tiling_y_changed(v: float) -> void:
	if _setting_slider: return
	if v <= _tiling_y_slider.max_value:
		_tiling_y_slider.value = v
	_live_update_selection()

func _on_tiling_y_slider(v: float) -> void:
	if _setting_slider: return
	_tiling_y_spin.value = v
	_live_update_selection()

func _on_tiling_scale_changed(v: float) -> void:
	if _setting_slider: return
	if v <= _tiling_scale_slider.max_value:
		_tiling_scale_slider.value = v
	_live_update_selection()

func _on_tiling_scale_slider(v: float) -> void:
	if _setting_slider: return
	_tiling_scale_spin.value = v
	_live_update_selection()


func _on_browse_texture() -> void:
	_file_dialog.popup_centered(Vector2i(600, 400))


func _on_texture_file_selected(path: String) -> void:
	_custom_tex_path.text = path
	_update_texture_list_selection()
	_update_pattern_visibility()
	_live_update_selection()


func _on_clear_texture() -> void:
	_custom_tex_path.text = ""
	_update_texture_list_selection()
	_update_pattern_visibility()
	_live_update_selection()


func _update_pattern_visibility() -> void:
	var name := _preset.get_item_text(_preset.selected)
	var is_basic := name == "Basic"
	var has_texture := not _custom_tex_path.text.is_empty()
	_pattern_row.visible = is_basic and not has_texture


func _live_update_selection() -> void:
	var nodes := _get_selected_mesh_nodes()
	if nodes.is_empty():
		return
	var mat := _build_current_material()
	for n in nodes:
		_apply_node(n, mat)
	EditorInterface.mark_scene_as_unsaved()


func _apply_node(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		n.material_override = mat
		n.set_meta("chroma_applied", true)
	elif n is MultiMeshInstance3D:
		n.material = mat
		n.set_meta("chroma_applied", true)


func _apply_to_node(n: Node) -> void:
	_apply_node(n, _build_current_material())


func _build_current_material() -> Material:
	var sx := _tiling_x_spin.value * _tiling_scale_spin.value
	var sy := _tiling_y_spin.value * _tiling_scale_spin.value
	return Materials.create_material(
		_preset.get_item_text(_preset.selected),
		_color_picker.color,
		_spec_spin.value,
		_rough_spin.value,
		_opacity_spin.value,
		_double_sided.button_pressed,
		_custom_tex_path.text,
		sx,
		sy,
		_uv_space.selected,
		_uv_mode.get_item_text(_uv_mode.selected).to_lower(),
		_pattern.get_item_text(_pattern.selected),
		_fix_tiling.button_pressed
	)


func _apply_selected() -> void:
	var nodes := _get_selected_mesh_nodes()
	if nodes.is_empty():
		_flash_status("Select mesh nodes first", Color(1, 0.5, 0))
		return
	var mat := _build_current_material()
	for n in nodes:
		_apply_node(n, mat)
	_save_cache()
	EditorInterface.mark_scene_as_unsaved()
	_set_status("Applied to " + str(nodes.size()) + " nodes", Color(0, 1, 0))


func _clear_selected() -> void:
	var nodes := _get_selected_mesh_nodes()
	if nodes.is_empty():
		_flash_status("Select mesh nodes first", Color(1, 0.5, 0))
		return
	for n in nodes:
		_clear_node(n)
	_save_cache()
	EditorInterface.mark_scene_as_unsaved()
	_flash_status("Cleared " + str(nodes.size()) + " nodes", Color(1, 0.7, 0))


func _apply_all() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		_flash_status("Open a scene first", Color(1, 0.5, 0))
		return

	var mode := _random_mode.selected
	var base_mat := _build_current_material()

	if mode == 1:
		var groups: Dictionary = {}
		_gather_groups_by_asset(root, groups)
		var keys: Array = groups.keys()
		keys.sort()
		for i in range(keys.size()):
			var col := _distinct_color(i, keys.size(), _random_seed)
			var mat := base_mat.duplicate()
			if mat is ShaderMaterial:
				mat.set_shader_parameter("albedo_color", col)
			elif mat is StandardMaterial3D:
				mat.albedo_color = col
			for n in groups[keys[i]]:
				_apply_node(n, mat)
		_random_seed += 1
	elif mode == 2:
		var nodes: Array[Node3D] = []
		_gather_mesh_nodes(root, nodes)
		for i in range(nodes.size()):
			var col := _distinct_color(i, nodes.size(), _random_seed)
			var mat := base_mat.duplicate()
			if mat is ShaderMaterial:
				mat.set_shader_parameter("albedo_color", col)
			elif mat is StandardMaterial3D:
				mat.albedo_color = col
			_apply_node(nodes[i], mat)
		_random_seed += 1
	else:
		var nodes: Array[Node3D] = []
		_gather_mesh_nodes(root, nodes)
		for n in nodes:
			_apply_node(n, base_mat)

	_save_cache()
	EditorInterface.mark_scene_as_unsaved()
	_set_status("Applied to all mesh nodes", Color(0, 1, 0))


func _clear_all() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		_flash_status("Open a scene first", Color(1, 0.5, 0))
		return
	var nodes: Array[Node3D] = []
	_gather_mesh_nodes(root, nodes)
	for n in nodes:
		_clear_node(n)
	_save_cache()
	EditorInterface.mark_scene_as_unsaved()
	_flash_status("Cleared all nodes", Color(1, 0.7, 0))


func _clear_node(n: Node) -> void:
	if n.has_meta("chroma_applied"):
		if n is MeshInstance3D:
			n.material_override = null
		elif n is MultiMeshInstance3D:
			n.material = null
		n.remove_meta("chroma_applied")


func _gather_groups_by_asset(n: Node, groups: Dictionary) -> void:
	if n is MeshInstance3D or n is MultiMeshInstance3D:
		var key := _asset_key_for_node(n)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(n)
	for c in n.get_children():
		_gather_groups_by_asset(c, groups)


func _asset_key_for_node(n: Node) -> String:
	if n.has_method("get_scene_file_path"):
		var p := n.get_scene_file_path()
		if typeof(p) == TYPE_STRING and p != "":
			return p
	if n is MeshInstance3D and n.mesh != null:
		if String(n.mesh.resource_path) != "":
			return String(n.mesh.resource_path)
	return str(n.get_class(), ":", n.name)


static func _distinct_color(i: int, total: int, seed: int = 0) -> Color:
	var hue := fmod((i + seed) * 0.61803398875, 1.0)
	return Color.from_hsv(hue, 0.4, 0.7, 1.0)


func _gather_mesh_nodes(n: Node, out: Array[Node3D]) -> void:
	if n is MeshInstance3D or n is MultiMeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_gather_mesh_nodes(c, out)


func _get_selected_mesh_nodes() -> Array[Node3D]:
	var sel := EditorInterface.get_selection()
	if not sel:
		return []
	var result: Array[Node3D] = []
	for n in sel.get_selected_nodes():
		_gather_mesh_nodes(n, result)
	return result


func _save_cache() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var assignments: Dictionary = {}
	_build_cache_recursive(root, root, assignments)
	Cache.save(root, assignments)


func _build_cache_recursive(n: Node, root: Node, out: Dictionary) -> void:
	if (n is MeshInstance3D or n is MultiMeshInstance3D) and n.has_meta("chroma_applied"):
		var np := root.get_path_to(n)
		var data := {
			"preset": _preset.get_item_text(_preset.selected),
			"color": _color_picker.color,
			"specular": _spec_spin.value,
			"roughness": _rough_spin.value,
			"opacity": _opacity_spin.value,
			"double_sided": _double_sided.button_pressed,
			"custom_texture": _custom_tex_path.text,
			"tiling_x": _tiling_x_spin.value,
			"tiling_y": _tiling_y_spin.value,
			"tiling_scale": _tiling_scale_spin.value,
			"uv_mode": _uv_mode.get_item_text(_uv_mode.selected).to_lower(),
			"uv_space": _uv_space.selected,
			"pattern": _pattern.get_item_text(_pattern.selected),
			"bomb": _fix_tiling.button_pressed,
		}
		out[str(np)] = data
	for c in n.get_children():
		_build_cache_recursive(c, root, out)


func load_cache() -> void:
	var root := EditorInterface.get_edited_scene_root()
	_scene_root = root
	if not root:
		return

	var assignments := Cache.load_for_scene(root)
	if assignments.is_empty():
		return

	for np_str in assignments.keys():
		var node := root.get_node_or_null(np_str)
		if not node:
			continue
		var data: Dictionary = assignments[np_str]

		var preset: String = data.get("preset", "Basic")
		var pidx := 0
		for i in range(_preset.item_count):
			if _preset.get_item_text(i) == preset:
				pidx = i
				break
		_preset.selected = pidx

		_color_picker.color = data.get("color", Color.WHITE)
		_set_slider_values({
			"spec": data.get("specular", 0.5),
			"rough": data.get("roughness", 0.5),
			"opacity": data.get("opacity", 1.0),
		})
		_double_sided.button_pressed = data.get("double_sided", true)
		_custom_tex_path.text = data.get("custom_texture", "")
		_update_texture_list_selection()

		_tiling_x_spin.value = data.get("tiling_x", 1.0)
		_tiling_y_spin.value = data.get("tiling_y", 1.0)
		_tiling_scale_spin.value = data.get("tiling_scale", 1.0)

		var uv_mode: String = data.get("uv_mode", "projected")
		var mode_idx := 0
		for i in range(_uv_mode.item_count):
			if _uv_mode.get_item_text(i).to_lower() == uv_mode:
				mode_idx = i
				break
		_uv_mode.selected = mode_idx
		var is_triplanar := uv_mode == "triplanar"
		_tiling_x_row.visible = not is_triplanar
		_tiling_y_row.visible = not is_triplanar

		_uv_space.selected = data.get("uv_space", UV_SPACE_LOCAL)

		var pattern: String = data.get("pattern", "None")
		for i in range(_pattern.item_count):
			if _pattern.get_item_text(i) == pattern:
				_pattern.selected = i
				break
		_update_pattern_visibility()

		var bomb: bool = data.get("bomb", false)
		_fix_tiling.button_pressed = bomb

		var scale_v: float = data.get("tiling_scale", 1.0)
		var mat := Materials.create_material(
			preset,
			data.get("color", Color.WHITE),
			data.get("specular", 0.5),
			data.get("roughness", 0.5),
			data.get("opacity", 1.0),
			data.get("double_sided", false),
			data.get("custom_texture", ""),
			data.get("tiling_x", 1.0) * scale_v,
			data.get("tiling_y", 1.0) * scale_v,
			data.get("uv_space", UV_SPACE_LOCAL),
			uv_mode,
			pattern,
			bomb
		)

		if node is MeshInstance3D:
			node.material_override = mat
		elif node is MultiMeshInstance3D:
			node.material = mat

		node.set_meta("chroma_applied", true)

	_set_status("Chroma restored for " + str(assignments.size()) + " nodes", Color(0, 1, 0))


func on_editor_scene_changed(_root: Node) -> void:
	load_cache()


func _clear_cache() -> void:
	Cache.clear_all()
	_flash_status("Cache cleared", Color(1, 0.7, 0))


func _open_cache() -> void:
	var path := Cache.get_cache_dir_path()
	OS.shell_open(path)


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _flash_status(text: String, color: Color) -> void:
	_set_status(text, color)
	if text.is_empty():
		return
	await get_tree().create_timer(1.5).timeout
	if _status and is_instance_valid(_status) and _status.text == text:
		_status.text = ""
