@tool
extends Node


const PRESETS := {
	"Bright": { "intensity": 1.5, "rotation": 0.0, "ambient": Color.WHITE, "ambient_strength": 0.8,
		"sun": true, "sun_elevation": 60.0, "sun_azimuth": 0.0, "sun_color": Color(1, 0.95, 0.85), "sun_energy": 1.5 },
	"Neutral": { "intensity": 1.0, "rotation": 90.0, "ambient": Color.WHITE, "ambient_strength": 0.6,
		"sun": true, "sun_elevation": 45.0, "sun_azimuth": 45.0, "sun_color": Color(1, 0.96, 0.90), "sun_energy": 1.0 },
	"Moody": { "intensity": 0.5, "rotation": 180.0, "ambient": Color(0.3, 0.3, 0.35), "ambient_strength": 0.3,
		"sun": true, "sun_elevation": 20.0, "sun_azimuth": 180.0, "sun_color": Color(0.8, 0.6, 0.4), "sun_energy": 0.4,
		"fog": true, "fog_density": 0.008, "fog_color": Color(0.3, 0.3, 0.35) },
	"Soft": { "intensity": 0.8, "rotation": 270.0, "ambient": Color.WHITE, "ambient_strength": 0.5,
		"sun": true, "sun_elevation": 35.0, "sun_azimuth": 135.0, "sun_color": Color(1, 0.92, 0.82), "sun_energy": 0.6 },
	"Warm": { "intensity": 1.2, "rotation": 45.0, "ambient": Color(1.0, 0.88, 0.65), "ambient_strength": 0.7,
		"sun": true, "sun_elevation": 30.0, "sun_azimuth": 270.0, "sun_color": Color(1.0, 0.7, 0.45), "sun_energy": 0.8 },
	"Cool": { "intensity": 0.8, "rotation": 135.0, "ambient": Color(0.65, 0.75, 1.0), "ambient_strength": 0.5,
		"sun": true, "sun_elevation": 50.0, "sun_azimuth": 90.0, "sun_color": Color(0.7, 0.8, 1.0), "sun_energy": 0.7 },
}

static func get_preset_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for key in PRESETS.keys():
		names.append(key)
	return names


static func get_hdri_files() -> PackedStringArray:
	var names: PackedStringArray = []
	var dir := DirAccess.open("res://addons/Kale/textures/")
	if dir:
		for f in dir.get_files():
			if f.get_extension().to_lower() == "hdr":
				names.append(f)
		names.sort()
	return names


static func apply_environment(
	hdri_filename: String,
	intensity: float,
	rotation: float,
	ambient_color: Color,
	ambient_strength: float,
) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var we := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if not we:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		root.add_child(we, true)
		we.set_owner(root)

	var env := we.environment
	if not env:
		env = Environment.new()
		env.resource_local_to_scene = true
		we.environment = env

	var mat := PanoramaSkyMaterial.new()
	if not hdri_filename.is_empty():
		var path := "res://addons/Kale/textures/" + hdri_filename
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex:
				mat.panorama = tex

	mat.energy_multiplier = clamp(intensity, 0.0, 4.0)

	var sky := Sky.new()
	sky.sky_material = mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.sky_rotation = Vector3(0, deg_to_rad(rotation), 0)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = clamp(ambient_strength, 0.0, 4.0)


static func update_sun(enabled: bool, elevation: float, azimuth: float, color: Color, energy: float) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return

	var sun := root.get_node_or_null("Sun") as DirectionalLight3D
	if not enabled:
		if sun:
			sun.queue_free()
		return

	if not sun:
		sun = DirectionalLight3D.new()
		sun.name = "Sun"
		root.add_child(sun, true)
		sun.set_owner(root)

	sun.rotation_degrees = Vector3(-elevation, azimuth, 0)
	sun.light_color = color
	sun.light_energy = energy


static func clear_sun() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var sun := root.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.queue_free()


static func disable_editor_preview_sun() -> void:
	var editor := EditorInterface.get_base_control()
	if not editor:
		return
	var sun_icon := editor.get_theme_icon("DirectionalLight", "EditorIcons")
	var buttons := editor.find_children("*", "BaseButton", true, false)
	for btn in buttons:
		var b := btn as BaseButton
		if not b:
			continue
		var tt := b.tooltip_text.strip_edges().to_lower()
		if "sun" in tt and "toggle" in tt:
			if b.icon == sun_icon:
				b.pressed.emit()
			return


static func clear_environment() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var we := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we:
		we.queue_free()
