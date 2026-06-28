@tool
extends Node


const PRESETS := {
	"Bright": { "intensity": 1.5, "rotation": 0.0, "ambient": Color.WHITE, "ambient_strength": 0.8 },
	"Neutral": { "intensity": 1.0, "rotation": 90.0, "ambient": Color.WHITE, "ambient_strength": 0.6 },
	"Moody": { "intensity": 0.5, "rotation": 180.0, "ambient": Color(0.3, 0.3, 0.35), "ambient_strength": 0.3 },
	"Soft": { "intensity": 0.8, "rotation": 270.0, "ambient": Color.WHITE, "ambient_strength": 0.5 },
	"Warm": { "intensity": 1.2, "rotation": 45.0, "ambient": Color(1.0, 0.88, 0.65), "ambient_strength": 0.7 },
	"Cool": { "intensity": 0.8, "rotation": 135.0, "ambient": Color(0.65, 0.75, 1.0), "ambient_strength": 0.5 },
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


static func clear_environment() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not root:
		return
	var we := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we:
		we.queue_free()
