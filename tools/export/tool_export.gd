@tool
extends KaleBase

const STEP_NAMES := ["Delete", "Import", "Copy Transforms", "Chroma", "Export"]
const ES_PREFIX := "kale/export/"

var _step_toggles: Array[CheckBox] = []
var _step_rows: Array[HBoxContainer] = []
var _del_input: LineEdit
var _status: Label


func get_tool_name() -> String:
	return "Export"


func _es_get(key: String, default):
	var es := EditorInterface.get_editor_settings()
	if es.has_setting(ES_PREFIX + key):
		return es.get_setting(ES_PREFIX + key)
	return default


func build_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)

	var lbl := Label.new()
	lbl.text = "Chain steps to run in order:"
	panel.add_child(lbl)

	var saved_order = _es_get("chain_order", [0, 1, 2, 3, 4]) as Array
	if saved_order.size() != 5:
		saved_order = [0, 1, 2, 3, 4]

	var step_list := VBoxContainer.new()
	for i in 5:
		var hbox := HBoxContainer.new()
		var toggle := CheckBox.new()
		toggle.text = STEP_NAMES[saved_order[i]]
		toggle.button_pressed = _es_get("enabled_" + str(i), true)
		toggle.toggled.connect(func(p: bool):
			var es := EditorInterface.get_editor_settings()
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

		if saved_order[i] == 0:
			_del_input = LineEdit.new()
			_del_input.placeholder_text = "unreal_export"
			_del_input.text = "unreal_export"
			_del_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(_del_input)

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
	if new_idx < 0 or new_idx >= 5:
		return
	var es := EditorInterface.get_editor_settings()
	var order = _es_get("chain_order", [0, 1, 2, 3, 4]) as Array
	var tmp = order[idx]
	order[idx] = order[new_idx]
	order[new_idx] = tmp
	es.set_setting(ES_PREFIX + "chain_order", order)

	var tmp_row = _step_rows[idx]
	_step_rows[idx] = _step_rows[new_idx]
	_step_rows[new_idx] = tmp_row

	var tmp_tog = _step_toggles[idx]
	_step_toggles[idx] = _step_toggles[new_idx]
	_step_toggles[new_idx] = tmp_tog

	list.move_child(tmp_row, new_idx)
	_rebuild_labels(order)


func _rebuild_labels(order: Array) -> void:
	for i in 5:
		_step_toggles[i].text = STEP_NAMES[order[i]]


func _run_chain() -> void:
	var order = _es_get("chain_order", [0, 1, 2, 3, 4]) as Array

	var total := 0
	for i in 5:
		if _step_toggles[i].button_pressed:
			total += 1
	if total == 0:
		_set_status("No steps enabled", Color(1, 0.5, 0))
		return

	var report: PackedStringArray = []
	var current := 0
	for i in 5:
		if not _step_toggles[i].button_pressed:
			continue
		var step_idx = order[i] as int
		current += 1
		_set_status("Step " + str(current) + "/" + str(total) + ": " + STEP_NAMES[step_idx])
		var ok = await _execute_step(step_idx)
		report.append(("✔ " if ok else "✘ ") + STEP_NAMES[step_idx])

	_set_status("Chain: " + ", ".join(report))


func _execute_step(idx: int) -> bool:
	match idx:
		0: return _step_delete()
		1: return await _step_import()
		2: return _step_copy()
		3: return _step_chroma()
		4: return _step_export()
	return false


func _step_import() -> bool:
	var tool := _find_tool("Import")
	if not tool or not tool.has_method("_on_import_pressed"):
		return false
	tool._on_import_pressed()
	await get_tree().process_frame
	return true


func _step_delete() -> bool:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return false
	var pattern := _del_input.text.strip_edges()
	if pattern.is_empty():
		return false
	var prefix := pattern.split("*")[0]
	if prefix.is_empty():
		return false

	var deleted := 0
	for child in root.get_children().duplicate():
		if child.name.begins_with(prefix):
			child.free()
			deleted += 1

	return deleted > 0


func _step_copy() -> bool:
	var tool := _find_tool("Copy Transforms")
	if not tool or not tool.has_method("_on_copy_pressed"):
		return false
	tool._on_copy_pressed()
	return true


func _step_chroma() -> bool:
	var tool := _find_tool("Chroma")
	if not tool or not tool.has_method("_apply_all"):
		return false
	tool._apply_all()
	return true


func _step_export() -> bool:
	var btn := EditorInterface.get_base_control().find_child("ExportLevel_Button", true, false)
	if not btn or not btn is BaseButton:
		return false
	btn.pressed.emit()
	return true


func _find_tool(name: String) -> KaleBase:
	var dock := get_parent().get_parent() as VBoxContainer
	if not dock:
		return null
	for child in dock.get_children():
		if child is Control and child.name == name and child.get_child_count() > 0:
			return child.get_child(child.get_child_count() - 1) as KaleBase
	return null


func _set_status(text: String, color: Color = Color.WHITE) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
