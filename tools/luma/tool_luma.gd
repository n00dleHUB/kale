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

var _sky_enabled: CheckBox
var _applied_hdri := ""

var _sun_enabled: CheckBox
var _sun_elevation_spin: SpinBox
var _sun_elevation_slider: HSlider
var _sun_azimuth_spin: SpinBox
var _sun_azimuth_slider: HSlider
var _sun_color: ColorPickerButton
var _sun_energy_spin: SpinBox
var _sun_energy_slider: HSlider

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
	_hdri_list.item_selected.connect(func(_idx): _on_changed())
	_panel.add_child(_hdri_list)

	# Sky section
	var sky_body := VBoxContainer.new()
	_sky_enabled = CheckBox.new()
	_sky_enabled.text = "Enable Custom Sky"
	_sky_enabled.toggled.connect(func(enabled: bool):
		if not enabled:
			_applied_hdri = ""
		_on_changed()
	)
	sky_body.add_child(_sky_enabled)
	_intensity_spin = SpinBox.new()
	_intensity_slider = HSlider.new()
	sky_body.add_child(_make_slider_row("Intensity:", _intensity_spin, _intensity_slider, 0.0, 4.0, 0.01, 1.0))
	_intensity_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_intensity_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_intensity_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_intensity_slider.value = v
		_setting_slider = false
		_on_changed()
	)

	_rotation_spin = SpinBox.new()
	_rotation_slider = HSlider.new()
	sky_body.add_child(_make_slider_row("Rotation:", _rotation_spin, _rotation_slider, 0.0, 360.0, 0.1, 0.0))
	_rotation_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_rotation_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_rotation_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_rotation_slider.value = v
		_setting_slider = false
		_on_changed()
	)

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
	_ambient_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_ambient_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_ambient_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_ambient_slider.value = v
		_setting_slider = false
		_on_changed()
	)

	_panel.add_child(_make_section("Ambient", false, amb_body))

	# Sun section
	var sun_body := VBoxContainer.new()

	_sun_enabled = CheckBox.new()
	_sun_enabled.text = "Enable Custom Sun"
	_sun_enabled.toggled.connect(func(enabled: bool):
		if not enabled:
			Env.disable_editor_preview_sun()
		_on_changed()
	)
	sun_body.add_child(_sun_enabled)

	_sun_elevation_spin = SpinBox.new()
	_sun_elevation_slider = HSlider.new()
	sun_body.add_child(_make_slider_row("Elevation:", _sun_elevation_spin, _sun_elevation_slider, 0.0, 90.0, 0.1, 45.0))
	_sun_elevation_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_elevation_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_sun_elevation_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_elevation_slider.value = v
		_setting_slider = false
		_on_changed()
	)

	_sun_azimuth_spin = SpinBox.new()
	_sun_azimuth_slider = HSlider.new()
	sun_body.add_child(_make_slider_row("Azimuth:", _sun_azimuth_spin, _sun_azimuth_slider, 0.0, 360.0, 0.1, 0.0))
	_sun_azimuth_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_azimuth_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_sun_azimuth_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_azimuth_slider.value = v
		_setting_slider = false
		_on_changed()
	)

	var sun_color_row := HBoxContainer.new()
	var sun_color_lbl := Label.new()
	sun_color_lbl.text = "Color:"
	sun_color_row.add_child(sun_color_lbl)
	_sun_color = ColorPickerButton.new()
	_sun_color.color = Color(1, 0.96, 0.9)
	_sun_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sun_color.color_changed.connect(func(_c): _on_changed())
	sun_color_row.add_child(_sun_color)
	sun_body.add_child(sun_color_row)

	_sun_energy_spin = SpinBox.new()
	_sun_energy_slider = HSlider.new()
	sun_body.add_child(_make_slider_row("Intensity:", _sun_energy_spin, _sun_energy_slider, 0.0, 10.0, 0.01, 1.0))
	_sun_energy_slider.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_energy_spin.value = v
		_setting_slider = false
		_on_changed()
	)
	_sun_energy_spin.value_changed.connect(func(v):
		if _setting_slider: return
		_setting_slider = true
		_sun_energy_slider.value = v
		_setting_slider = false
		_on_changed()
	)

	_panel.add_child(_make_section("Sun", true, sun_body))

	var neutral_idx := 0
	for i in range(_preset.item_count):
		if _preset.get_item_text(i) == "Neutral":
			neutral_idx = i
			break
	_preset.select(neutral_idx)
	_on_preset_changed(neutral_idx)

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
	_sky_enabled.button_pressed = data.get("sky", true)
	_sun_enabled.button_pressed = data.get("sun", true)
	_sun_elevation_slider.value = data.get("sun_elevation", 45.0)
	_sun_elevation_spin.value = data.get("sun_elevation", 45.0)
	_sun_azimuth_slider.value = data.get("sun_azimuth", 0.0)
	_sun_azimuth_spin.value = data.get("sun_azimuth", 0.0)
	_sun_color.color = data.get("sun_color", Color(1, 0.96, 0.9))
	_sun_energy_slider.value = data.get("sun_energy", 1.0)
	_sun_energy_spin.value = data.get("sun_energy", 1.0)
	_setting_slider = false
	_live_update()


func _on_changed() -> void:
	if _setting_slider:
		return
	_live_update()


func _live_update() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var we := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if _sky_enabled.button_pressed:
		var hdri := ""
		if _hdri_list.selected > 0:
			hdri = _hdri_list.get_item_text(_hdri_list.selected)

		if not we or not we.environment or not we.environment.sky or hdri != _applied_hdri:
			_applied_hdri = hdri
			Env.apply_environment(
				hdri,
				_intensity_spin.value,
				_rotation_spin.value,
				_ambient_color.color,
				_ambient_spin.value,
			)
		elif we.environment:
			we.environment.sky_rotation = Vector3(0, deg_to_rad(_rotation_spin.value), 0)
			we.environment.ambient_light_color = _ambient_color.color
			we.environment.ambient_light_energy = _ambient_spin.value
			if we.environment.sky:
				var mat := we.environment.sky.sky_material as PanoramaSkyMaterial
				if mat:
					mat.energy_multiplier = _intensity_spin.value
	else:
		if we:
			_applied_hdri = ""
			we.queue_free()

	Env.update_sun(
		_sun_enabled.button_pressed,
		_sun_elevation_spin.value,
		_sun_azimuth_spin.value,
		_sun_color.color,
		_sun_energy_spin.value,
	)
