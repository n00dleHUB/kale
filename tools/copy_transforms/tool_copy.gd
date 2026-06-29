@tool
extends KaleBase

var _panel: VBoxContainer


func get_tool_name() -> String:
	return "Copy Transforms"


func build_panel() -> Control:
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)

	# Source row
	var src_row = HBoxContainer.new()
	var src_lbl = Label.new()
	src_lbl.text = "Source:"
	src_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	src_row.add_child(src_lbl)

	var src_path = LineEdit.new()
	src_path.placeholder_text = "Select a node in viewport"
	src_path.text = "pos"
	src_path.editable = false
	src_path.custom_minimum_size = Vector2(180, 0)
	src_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	src_path.set_meta("role", "source")
	src_row.add_child(src_path)

	var src_btn = Button.new()
	src_btn.text = "Select"
	src_btn.pressed.connect(_on_select_node.bind(src_path))
	src_row.add_child(src_btn)

	_panel.add_child(src_row)

	# Target row
	var tgt_row = HBoxContainer.new()
	var tgt_lbl = Label.new()
	tgt_lbl.text = "Target:"
	tgt_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tgt_row.add_child(tgt_lbl)

	var tgt_path = LineEdit.new()
	tgt_path.placeholder_text = "Select a node in viewport"
	tgt_path.text = "unreal_export"
	tgt_path.editable = false
	tgt_path.custom_minimum_size = Vector2(180, 0)
	tgt_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tgt_path.set_meta("role", "target")
	tgt_row.add_child(tgt_path)

	var tgt_btn = Button.new()
	tgt_btn.text = "Select"
	tgt_btn.pressed.connect(_on_select_node.bind(tgt_path))
	tgt_row.add_child(tgt_btn)

	_panel.add_child(tgt_row)

	# Toggles: Position, Rotation, Scale
	var toggle_row = HBoxContainer.new()
	var pos_toggle = CheckBox.new()
	pos_toggle.text = "Position"
	pos_toggle.button_pressed = true
	pos_toggle.name = "toggle_pos"
	toggle_row.add_child(pos_toggle)

	var rot_toggle = CheckBox.new()
	rot_toggle.text = "Rotation"
	rot_toggle.button_pressed = true
	rot_toggle.name = "toggle_rot"
	toggle_row.add_child(rot_toggle)

	var scl_toggle = CheckBox.new()
	scl_toggle.text = "Scale"
	scl_toggle.button_pressed = true
	scl_toggle.name = "toggle_scl"
	toggle_row.add_child(scl_toggle)

	_panel.add_child(toggle_row)

	# Copy button
	var copy_btn = Button.new()
	copy_btn.text = "Copy Transform"
	copy_btn.name = "copy_btn"
	copy_btn.pressed.connect(_on_copy_pressed)
	_panel.add_child(copy_btn)

	# Status label
	var status = Label.new()
	status.text = ""
	status.name = "status_label"
	status.add_theme_color_override("font_color", Color(0, 1, 0))
	_panel.add_child(status)

	return _panel


func _on_select_node(path_field: LineEdit) -> void:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if selected.size() > 0:
		var node = selected[0]
		var root := EditorInterface.get_edited_scene_root()
		if root and root.is_ancestor_of(node):
			path_field.text = node.name
			path_field.set_meta("node_path", root.get_path_to(node))
		else:
			path_field.text = ""
			path_field.remove_meta("node_path")
	else:
		path_field.text = ""
		path_field.remove_meta("node_path")


func _on_copy_pressed() -> void:
	var src_path_field = _find_field("source")
	var tgt_path_field = _find_field("target")

	if not src_path_field or not tgt_path_field:
		return

	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var source: Node3D = null
	var target: Node3D = null

	if src_path_field.has_meta("node_path"):
		var n = root.get_node(src_path_field.get_meta("node_path"))
		if n is Node3D:
			source = n

	if tgt_path_field.has_meta("node_path"):
		var n = root.get_node(tgt_path_field.get_meta("node_path"))
		if n is Node3D:
			target = n

	if not source:
		var name = src_path_field.text.strip_edges()
		if name.is_empty():
			_show_status("Source node not found — re-select it", Color(1, 0, 0))
			src_path_field.text = ""
			src_path_field.remove_meta("node_path")
			return
		source = root.find_child(name, true, false)
		if not source:
			_show_status("Source node not found — re-select it", Color(1, 0, 0))
			src_path_field.text = ""
			src_path_field.remove_meta("node_path")
			return

	if not target:
		var name = tgt_path_field.text.strip_edges()
		if name.is_empty():
			_show_status("Target node not found — re-select it", Color(1, 0, 0))
			tgt_path_field.text = ""
			tgt_path_field.remove_meta("node_path")
			return
		target = root.find_child(name, true, false)
		if not target:
			_show_status("Target node not found — re-select it", Color(1, 0, 0))
			tgt_path_field.text = ""
			tgt_path_field.remove_meta("node_path")
			return

	var pos = _find_toggle("toggle_pos").button_pressed
	var rot = _find_toggle("toggle_rot").button_pressed
	var scl = _find_toggle("toggle_scl").button_pressed

	CopyTransforms.copy_all(source, target, pos, rot, scl)
	_show_status("Transform Copied!", Color(0, 1, 0))


func _find_field(role: String) -> LineEdit:
	for child in _panel.get_children():
		var row = child as HBoxContainer
		if row:
			for c in row.get_children():
				var field = c as LineEdit
				if field and field.get_meta("role", "") == role:
					return field
	return null


func _find_toggle(name: String) -> CheckBox:
	for child in _panel.get_children(true):
		var cb = child as CheckBox
		if cb and cb.name == name:
			return cb
		for grandchild in child.get_children():
			cb = grandchild as CheckBox
			if cb and cb.name == name:
				return cb
	return null


func _show_status(text: String, color: Color) -> void:
	var label = _panel.get_node("status_label") as Label
	if label:
		label.text = text
		label.add_theme_color_override("font_color", color)
