@tool
extends KaleBase

const STEP_NAMES := ["Import", "Copy Transforms", "Chroma", "Export"]
const ES_PREFIX := "kale/export/"

var _step_toggles: Array[CheckBox] = []
var _step_rows: Array[HBoxContainer] = []
var _status: Label


func get_tool_name() -> String:
	return "Export"


func build_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)

	var lbl := Label.new()
	lbl.text = "Chain steps to run in order:"
	panel.add_child(lbl)

	var es := EditorInterface.get_editor_settings()
	var saved_order := es.get_setting(ES_PREFIX + "chain_order", []) as Array
	if saved_order.size() != 4:
		saved_order = [0, 1, 2, 3]

	var step_list := VBoxContainer.new()
	for i in 4:
		var hbox := HBoxContainer.new()
		var toggle := CheckBox.new()
		toggle.text = STEP_NAMES[saved_order[i]]
		toggle.button_pressed = es.get_setting(ES_PREFIX + "enabled_" + str(i), true)
		toggle.toggled.connect(func(p: bool):
			es.set_setting(ES_PREFIX + "enabled_" + str(i), p)
		)
		hbox.add_child(toggle)

		var up := Button.new()
		up.text = "▲"
		up.custom_minimum_size = Vector2(24, 22)
		up.pressed.connect(_move_step.bind(i, -1, step_list))
		hbox.add_child(up)

		var down := Button.new()
		down.text = "▼"
		down.custom_minimum_size = Vector2(24, 22)
		down.pressed.connect(_move_step.bind(i, 1, step_list))
		hbox.add_child(down)

		_step_toggles.append(toggle)
		_step_rows.append(hbox)
		step_list.add_child(hbox)

	panel.add_child(step_list)

	var run_btn := Button.new()
	run_btn.text = "Run Chain"
	run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_btn.pressed.connect(_run_chain)
	panel.add_child(run_btn)

	_status = Label.new()
	_status.text = ""
	panel.add_child(_status)

	return panel


func _move_step(idx: int, dir: int, list: VBoxContainer) -> void:
	var new_idx := idx + dir
	if new_idx < 0 or new_idx >= 4:
		return
	var es := EditorInterface.get_editor_settings()
	var order := es.get_setting(ES_PREFIX + "chain_order", [0, 1, 2, 3]) as Array
	var tmp := order[idx]
	order[idx] = order[new_idx]
	order[new_idx] = tmp
	es.set_setting(ES_PREFIX + "chain_order", order)

	var tmp_row := _step_rows[idx]
	_step_rows[idx] = _step_rows[new_idx]
	_step_rows[new_idx] = tmp_row

	var tmp_tog := _step_toggles[idx]
	_step_toggles[idx] = _step_toggles[new_idx]
	_step_toggles[new_idx] = tmp_tog

	list.move_child(tmp_row, new_idx)
	_rebuild_labels(order)


func _rebuild_labels(order: Array) -> void:
	for i in 4:
		_step_toggles[i].text = STEP_NAMES[order[i]]


func _run_chain() -> void:
	var es := EditorInterface.get_editor_settings()
	var order := es.get_setting(ES_PREFIX + "chain_order", [0, 1, 2, 3]) as Array

	var total := 0
	for i in 4:
		if _step_toggles[i].button_pressed:
			total += 1
	if total == 0:
		_set_status("No steps enabled", Color(1, 0.5, 0))
		return

	var current := 0
	for i in 4:
		if not _step_toggles[i].button_pressed:
			continue
		var step_idx := order[i] as int
		current += 1
		_set_status("Step " + str(current) + "/" + str(total) + ": " + STEP_NAMES[step_idx])
		await _execute_step(step_idx)

	_set_status("Chain complete (" + str(total) + " steps)", Color(0, 1, 0))


func _execute_step(idx: int) -> void:
	match idx:
		0: _step_import()
		1: _step_copy()
		2: _step_chroma()
		3: _step_export()


func _step_import() -> void:
	var tool := _find_tool("Import")
	if not tool or not tool.has_method("_on_import_pressed"):
		_set_status("Import tool not found", Color(1, 0.5, 0))
		return
	tool._on_import_pressed()


func _step_copy() -> void:
	var tool := _find_tool("Copy Transforms")
	if not tool or not tool.has_method("_on_copy_pressed"):
		_set_status("Copy Transform tool not found", Color(1, 0.5, 0))
		return
	tool._on_copy_pressed()


func _step_chroma() -> void:
	var tool := _find_tool("Chroma")
	if not tool or not tool.has_method("_apply_all"):
		_set_status("Chroma tool not found", Color(1, 0.5, 0))
		return
	tool._apply_all()


func _step_export() -> void:
	var btn := EditorInterface.get_base_control().find_child("ExportLevel_Button", true, false)
	if not btn or not btn is BaseButton:
		_set_status("Export Level button not found (bfPortal loaded?)", Color(1, 0.5, 0))
		return
	btn.pressed.emit()


func _find_tool(name: String) -> KaleBase:
	var dock := get_parent().get_parent() as VBoxContainer
	if not dock:
		return null
	for child in dock.get_children():
		if child is Control and child.name == name and child.get_child_count() > 0:
			return child.get_child(0) as KaleBase
	return null


func _set_status(text: String, color: Color = Color.WHITE) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
