@tool
extends KaleBase


const Env = preload("res://addons/Kale/tools/luma/luma_environment.gd")

var _panel: VBoxContainer
var _preset: OptionButton
var _hdri_list: OptionButton
var _intensity_spin: SpinBox
var _intensity_slider: HSlider
var _rotation_spin: SpinBox
var _rotation_slider: HSlider
var _ambient_color: ColorPickerButton
var _ambient_spin: SpinBox
var _ambient_slider: HSlider
var _status: Label

var _setting_slider := false


func get_tool_name() -> String:
	return "Luma"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(380, 0)

	# Preset section
	var pres_lbl := Label.new()
	pres_lbl.text = "Preset:"
	_panel.add_child(pres_lbl)

	_preset = OptionButton.new()
	_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for p in Env.get_preset_names():
		_preset.add_item(p)
	_preset.item_selected.connect(_on_preset_changed)
	_panel.add_child(_preset)

	# HDRI section
	var hdr_lbl := Label.new()
	hdr_lbl.text = "HDRI:"
	_panel.add_child(hdr_lbl)

	_hdri_list = OptionButton.new()
	_hdri_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hdri_list.add_item("(None)")
	for f in Env.get_hdri_files():
		_hdri_list.add_item(f)
	_hdri_list.select(1)
	_panel.add_child(_hdri_list)

	# Sky section
	var sky_body := VBoxContainer.new()
	_intensity_spin = SpinBox.new()
	_intensity_slider = HSlider.new()
	sky_body.add_child(_make_slider_row("Intensity:", _intensity_spin, _intensity_slider, 0.0, 4.0, 0.01, 1.0))
	_intensity_spin.value_changed.connect(func(_v): _on_changed())

	_rotation_spin = SpinBox.new()
	_rotation_slider = HSlider.new()
	sky_body.add_child(_make_slider_row("Rotation:", _rotation_spin, _rotation_slider, 0.0, 360.0, 0.1, 0.0))
	_rotation_spin.value_changed.connect(func(_v): _on_changed())

	_panel.add_child(_make_section("Sky", false, sky_body))

	# Ambient section
	var amb_body := VBoxContainer.new()
	var amb_row := HBoxContainer.new()
	var amb_lbl := Label.new()
	amb_lbl.text = "Color:"
	amb_row.add_child(amb_lbl)

	_ambient_color = ColorPickerButton.new()
	_ambient_color.color = Color.WHITE
	_ambient_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ambient_color.color_changed.connect(func(_c): _on_changed())
	amb_row.add_child(_ambient_color)
	amb_body.add_child(amb_row)

	_ambient_spin = SpinBox.new()
	_ambient_slider = HSlider.new()
	amb_body.add_child(_make_slider_row("Strength:", _ambient_spin, _ambient_slider, 0.0, 4.0, 0.01, 0.6))
	_ambient_spin.value_changed.connect(func(_v): _on_changed())

	_panel.add_child(_make_section("Ambient", false, amb_body))

	# Buttons
	var btn_row := HBoxContainer.new()
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.pressed.connect(_on_apply)
	btn_row.add_child(apply_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear)
	btn_row.add_child(clear_btn)
	_panel.add_child(btn_row)

	# Status
	_status = Label.new()
	_status.text = ""
	_panel.add_child(_status)

	_on_preset_changed(0)

	return _panel


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


func _on_preset_changed(idx: int) -> void:
	var name := _preset.get_item_text(idx)
	var data := Env.PRESETS.get(name, {})
	_setting_slider = true
	_intensity_slider.value = data.get("intensity", 1.0)
	_intensity_spin.value = data.get("intensity", 1.0)
	_rotation_slider.value = data.get("rotation", 0.0)
	_rotation_spin.value = data.get("rotation", 0.0)
	_ambient_color.color = data.get("ambient", Color.WHITE)
	_ambient_slider.value = data.get("ambient_strength", 0.6)
	_ambient_spin.value = data.get("ambient_strength", 0.6)
	_setting_slider = false


func _on_changed() -> void:
	if _setting_slider:
		return
	_flash_status("Values changed — Apply to update", Color(0.8, 0.8, 0.3))


func _on_apply() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		_flash_status("Open a scene first", Color(1, 0.5, 0))
		return

	var hdri := ""
	if _hdri_list.selected > 0:
		hdri = _hdri_list.get_item_text(_hdri_list.selected)

	Env.apply_environment(
		hdri,
		_intensity_spin.value,
		_rotation_spin.value,
		_ambient_color.color,
		_ambient_spin.value,
	)
	_flash_status("Environment applied", Color(0, 1, 0))


func _on_clear() -> void:
	Env.clear_environment()
	_flash_status("Environment cleared", Color(1, 0.7, 0))


func _flash_status(msg: String, col: Color) -> void:
	_status.text = msg
	_status.add_theme_color_override("font_color", col)

	var tween := create_tween().set_delay(2.5)
	tween.tween_property(_status, "modulate", Color.TRANSPARENT, 0.5)
	tween.finished.connect(func():
		_status.text = ""
		_status.modulate = Color.WHITE
	)
