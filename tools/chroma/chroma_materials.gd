@tool
extends Node


const PRESETS := {
	"Basic": { "color": Color(0.75, 0.75, 0.75), "rough": 0.5, "spec": 0.5, "opacity": 1.0, "tiling": 1.0, "texture": "" },
	"Asphalt": { "color": Color.WHITE, "rough": 0.9, "spec": 0.3, "opacity": 1.0, "tiling": 3.0, "texture": "res://addons/Kale/textures/asphalt.png" },
	"Bricks": { "color": Color.WHITE, "rough": 0.8, "spec": 0.3, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/bricks.png" },
	"Concrete": { "color": Color.WHITE, "rough": 0.9, "spec": 0.3, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/concrete.png" },
	"Dirt": { "color": Color.WHITE, "rough": 1.0, "spec": 0.1, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/dirt.png" },
	"Glass": { "color": Color(0.78, 0.85, 0.98), "rough": 0.05, "spec": 1.0, "opacity": 0.2, "tiling": 1.0, "texture": "" },
	"Gravel": { "color": Color.WHITE, "rough": 1.0, "spec": 0.2, "opacity": 1.0, "tiling": 4.0, "texture": "res://addons/Kale/textures/gravel.png" },
	"Metal": { "color": Color.WHITE, "rough": 0.5, "spec": 1.0, "opacity": 1.0, "tiling": 3.0, "texture": "res://addons/Kale/textures/metal.png" },
	"Planks": { "color": Color.WHITE, "rough": 0.7, "spec": 0.4, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/planks.png" },
	"Rock": { "color": Color.WHITE, "rough": 0.9, "spec": 0.2, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/rock.png" },
	"Rocks River": { "color": Color.WHITE, "rough": 0.9, "spec": 0.2, "opacity": 1.0, "tiling": 3.0, "texture": "res://addons/Kale/textures/rocks_river.png" },
	"Rocky Terrain": { "color": Color.WHITE, "rough": 1.0, "spec": 0.2, "opacity": 1.0, "tiling": 3.0, "texture": "res://addons/Kale/textures/rocky_terrain.png" },
	"Sand": { "color": Color.WHITE, "rough": 1.0, "spec": 0.1, "opacity": 1.0, "tiling": 3.0, "texture": "res://addons/Kale/textures/sand.png" },
	"Tiles Checker": { "color": Color.WHITE, "rough": 0.6, "spec": 0.5, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/tiles_checker.png" },
	"Tiles Marble": { "color": Color.WHITE, "rough": 0.3, "spec": 0.7, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/tiles_marble.png" },
	"Tiles Terracotta": { "color": Color.WHITE, "rough": 0.7, "spec": 0.4, "opacity": 1.0, "tiling": 2.0, "texture": "res://addons/Kale/textures/tiles_terracotta.png" },
	"UV": { "color": Color.WHITE, "rough": 0.5, "spec": 0.5, "opacity": 1.0, "tiling": 1.0, "texture": "" },
	"Water": { "color": Color(0.2, 0.4, 0.7), "rough": 0.1, "spec": 0.8, "opacity": 0.75, "tiling": 2.0, "texture": "" },
	"Wood": { "color": Color.WHITE, "rough": 0.7, "spec": 0.3, "opacity": 1.0, "tiling": 4.0, "texture": "res://addons/Kale/textures/wood.png" },
}

const PATTERN_NAMES := ["None", "Grid", "Rings", "Planks", "Tiles", "Lines", "Hexagon", "Diagonal", "Triangles"]

const UV_MODE_PROJECTED := "projected"
const UV_MODE_TRIPLANAR := "triplanar"

const PROJECTED_SHADER_CODE := """
shader_type spatial;
render_mode __BLEND__ __CULL__, shadows_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float specular = 0.5;
uniform float roughness = 0.5;
uniform float tiling_x = 1.0;
uniform float tiling_y = 1.0;
uniform float alpha = 1.0;
uniform bool world_space = false;

void vertex() {
	vec3 pos = world_space ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
	UV = pos.xz * vec2(tiling_x, tiling_y);
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * albedo_color.rgb;
	METALLIC = 0.0;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	__ALPHA_LINE__
}
"""

const PROJECTED_NOISE_SHADER_CODE := """
shader_type spatial;
render_mode __BLEND__ __CULL__, shadows_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float specular = 0.5;
uniform float roughness = 0.5;
uniform float tiling_x = 1.0;
uniform float tiling_y = 1.0;
uniform float alpha = 1.0;
uniform bool world_space = false;

float _random(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float _noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = _random(i);
	float b = _random(i + vec2(1.0, 0.0));
	float c = _random(i + vec2(0.0, 1.0));
	float d = _random(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec2 _noise2(vec2 p) {
	return vec2(_noise(p), _noise(p + vec2(100.0, 0.0)));
}

vec4 _sample(vec2 cell, vec2 uv) {
	vec2 center = cell + vec2(0.5);
	vec2 rel = uv - center;

	float angle = (_random(cell) - 0.5) * 1.57;
	float ca = cos(angle);
	float sa = sin(angle);
	vec2 rot = vec2(rel.x * ca - rel.y * sa, rel.x * sa + rel.y * ca);

	vec2 off = vec2(
		(_random(cell + vec2(50.0, 0.0)) - 0.5) * 0.5,
		(_random(cell + vec2(0.0, 50.0)) - 0.5) * 0.5
	);

	float scale = 0.7 + _random(cell + vec2(100.0, 0.0)) * 0.6;

	return texture(albedo_texture, center + rot * scale + off);
}

void vertex() {
	vec3 pos = world_space ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
	UV = pos.xz * vec2(tiling_x, tiling_y);
}

void fragment() {
	vec2 cell = floor(UV);
	vec2 f = fract(UV);
	vec2 t = f * f * (3.0 - 2.0 * f);

	vec4 c00 = _sample(cell + vec2(0.0, 0.0), UV);
	vec4 c10 = _sample(cell + vec2(1.0, 0.0), UV);
	vec4 c01 = _sample(cell + vec2(0.0, 1.0), UV);
	vec4 c11 = _sample(cell + vec2(1.0, 1.0), UV);

	vec4 tex = mix(mix(c00, c10, t.x), mix(c01, c11, t.x), t.y);
	ALBEDO = tex.rgb * albedo_color.rgb;
	METALLIC = 0.0;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	__ALPHA_LINE__
}
"""

const TRIPLANAR_BOMB_SHADER_CODE := """
shader_type spatial;
render_mode __BLEND__ __CULL__, shadows_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float specular = 0.5;
uniform float roughness = 0.5;
uniform float tiling = 1.0;
uniform float alpha = 1.0;
uniform bool world_space = false;

varying vec3 v_pos;
varying vec3 v_normal;

float _random(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec4 _sample(vec2 cell, vec2 uv) {
	vec2 center = cell + vec2(0.5);
	vec2 rel = uv - center;

	float angle = (_random(cell) - 0.5) * 1.57;
	float ca = cos(angle);
	float sa = sin(angle);
	vec2 rot = vec2(rel.x * ca - rel.y * sa, rel.x * sa + rel.y * ca);

	vec2 off = vec2(
		(_random(cell + vec2(50.0, 0.0)) - 0.5) * 0.5,
		(_random(cell + vec2(0.0, 50.0)) - 0.5) * 0.5
	);

	float scale = 0.7 + _random(cell + vec2(100.0, 0.0)) * 0.6;

	return texture(albedo_texture, center + rot * scale + off);
}

vec4 _bomb(vec2 uv) {
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	vec2 t = f * f * (3.0 - 2.0 * f);

	vec4 c00 = _sample(cell + vec2(0.0, 0.0), uv);
	vec4 c10 = _sample(cell + vec2(1.0, 0.0), uv);
	vec4 c01 = _sample(cell + vec2(0.0, 1.0), uv);
	vec4 c11 = _sample(cell + vec2(1.0, 1.0), uv);

	return mix(mix(c00, c10, t.x), mix(c01, c11, t.x), t.y);
}

void vertex() {
	vec3 pos = world_space ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
	vec3 nml = world_space ? normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz) : NORMAL;
	v_pos = pos;
	v_normal = nml;
}

void fragment() {
	vec3 w = abs(v_normal);
	w /= w.x + w.y + w.z;

	vec4 tx = _bomb(v_pos.zy * tiling);
	vec4 ty = _bomb(v_pos.xz * tiling);
	vec4 tz = _bomb(v_pos.xy * tiling);

	vec4 tex = tx * w.x + ty * w.y + tz * w.z;
	ALBEDO = tex.rgb * albedo_color.rgb;
	METALLIC = 0.0;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	__ALPHA_LINE__
}
"""


static func create_material(
	preset: String,
	color: Color,
	specular: float,
	roughness: float,
	opacity: float,
	double_sided: bool,
	custom_texture: String,
	tiling_x: float,
	tiling_y: float,
	uv_space: int,
	uv_mode: String,
	pattern: String = "",
	fix_tiling: bool = false
) -> Material:
	if uv_mode == UV_MODE_PROJECTED:
		return _create_projected(color, specular, roughness, opacity, double_sided, custom_texture, preset, pattern, tiling_x, tiling_y, uv_space, fix_tiling)

	if uv_mode == UV_MODE_TRIPLANAR and fix_tiling:
		var t := clamp(tiling_x, 0.01, 50.0)
		return _create_triplanar_bomb(color, specular, roughness, opacity, double_sided, custom_texture, preset, pattern, t, uv_space)

	var mat := StandardMaterial3D.new()
	mat.metallic_specular = clamp(specular, 0.0, 1.0)
	mat.roughness = clamp(roughness, 0.0, 1.0)
	mat.metallic = 0.0

	var tex := _resolve_texture(custom_texture, preset, pattern)
	if tex:
		mat.albedo_texture = tex

	mat.albedo_color = color

	if opacity < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.albedo_color.a = clamp(opacity, 0.0, 1.0)

	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		mat.cull_mode = BaseMaterial3D.CULL_BACK

	var sx := clamp(tiling_x, 0.01, 50.0)
	var sy := clamp(tiling_y, 0.01, 50.0)
	if uv_mode == UV_MODE_TRIPLANAR:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = (uv_space == 1)
		mat.uv1_scale = Vector3(sx, sx, sx)
	else:
		mat.uv1_triplanar = false
		mat.uv1_scale = Vector3(sx, sy, 1.0)

	return mat


static func _create_projected(
	color: Color,
	specular: float,
	roughness: float,
	opacity: float,
	double_sided: bool,
	custom_texture: String,
	preset: String,
	pattern: String,
	tiling_x: float,
	tiling_y: float,
	uv_space: int,
	fix_tiling: bool = false
) -> Material:
	var cull_mode := "cull_disabled" if double_sided else "cull_back"
	var blend_mode := "blend_mix, " if opacity < 1.0 else ""
	var alpha_line := "\tALPHA = tex.a * albedo_color.a * alpha;\n" if opacity < 1.0 else ""
	var src := PROJECTED_NOISE_SHADER_CODE if fix_tiling else PROJECTED_SHADER_CODE
	var code := src.replace("__BLEND__", blend_mode).replace("__ALPHA_LINE__", alpha_line).replace("__CULL__", cull_mode)
	var shader := Shader.new()
	shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var tex := _resolve_texture(custom_texture, preset, pattern)
	if tex:
		mat.set_shader_parameter("albedo_texture", tex)

	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("specular", clamp(specular, 0.0, 1.0))
	mat.set_shader_parameter("roughness", clamp(roughness, 0.0, 1.0))
	mat.set_shader_parameter("alpha", clamp(opacity, 0.0, 1.0))
	mat.set_shader_parameter("tiling_x", clamp(tiling_x * 0.1, 0.001, 50.0))
	mat.set_shader_parameter("tiling_y", clamp(tiling_y * 0.1, 0.001, 50.0))
	mat.set_shader_parameter("world_space", uv_space == 1)

	return mat


static func _create_triplanar_bomb(
	color: Color,
	specular: float,
	roughness: float,
	opacity: float,
	double_sided: bool,
	custom_texture: String,
	preset: String,
	pattern: String,
	tiling: float,
	uv_space: int
) -> Material:
	var cull_mode := "cull_disabled" if double_sided else "cull_back"
	var blend_mode := "blend_mix, " if opacity < 1.0 else ""
	var alpha_line := "\tALPHA = tex.a * albedo_color.a * alpha;\n" if opacity < 1.0 else ""
	var code := TRIPLANAR_BOMB_SHADER_CODE.replace("__BLEND__", blend_mode).replace("__ALPHA_LINE__", alpha_line).replace("__CULL__", cull_mode)
	var shader := Shader.new()
	shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var tex := _resolve_texture(custom_texture, preset, pattern)
	if tex:
		mat.set_shader_parameter("albedo_texture", tex)

	mat.set_shader_parameter("albedo_color", color)
	mat.set_shader_parameter("specular", clamp(specular, 0.0, 1.0))
	mat.set_shader_parameter("roughness", clamp(roughness, 0.0, 1.0))
	mat.set_shader_parameter("alpha", clamp(opacity, 0.0, 1.0))
	mat.set_shader_parameter("tiling", clamp(tiling * 0.1, 0.001, 50.0))
	mat.set_shader_parameter("world_space", uv_space == 1)

	return mat


static func _resolve_texture(custom_texture: String, preset: String, pattern: String) -> Texture2D:
	if not custom_texture.is_empty() and ResourceLoader.exists(custom_texture):
		var res = load(custom_texture)
		if res is Texture2D:
			return res

	if preset == "Basic" and not pattern.is_empty() and pattern != "None":
		return _gen_pattern(pattern)

	if preset == "UV":
		return _make_checkerboard()

	var pdata := PRESETS.get(preset, {})
	var tex_path: String = pdata.get("texture", "")
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		var res = load(tex_path)
		if res is Texture2D:
			return res

	return null


static func _gen_pattern(name: String) -> Texture2D:
	match name:
		"Grid": return _make_grid()
		"Rings": return _make_rings()
		"Planks": return _make_planks()
		"Tiles": return _make_tiles()
		"Lines": return _make_lines()
		"Hexagon": return _make_hexagon()
		"Diagonal": return _make_diagonal()
		"Triangles": return _make_triangles()
	return null


static func _make_checkerboard() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cell := 64
	for y in range(sz):
		for x in range(sz):
			var cx := (x / cell) % 2
			var cy := (y / cell) % 2
			var v := 0.95 if cx == cy else 0.05
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_grid() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cell := 64
	for y in range(sz):
		for x in range(sz):
			var cx := (x / cell) % 2
			var cy := (y / cell) % 2
			var light := cx == cy
			var edge := (x % cell) <= 2 or (x % cell) >= cell - 3 or (y % cell) <= 2 or (y % cell) >= cell - 3
			var v := 0.95 if light else 0.78
			if edge:
				v *= 0.6
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_rings() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cx := sz / 2.0
	var cy := sz / 2.0
	for y in range(sz):
		for x in range(sz):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var dist := sqrt(dx * dx + dy * dy)
			var ring := sin(dist * 0.15) * 0.5 + 0.5
			var v := 0.3 + ring * 0.4
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_planks() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var plank_h := 64
	for y in range(sz):
		var plank := (y / plank_h) % 2
		var gap := (y % plank_h) <= 2
		for x in range(sz):
			var v := 0.6 if plank == 0 else 0.45
			if gap:
				v = 0.1
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_tiles() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var tile := 64
	for y in range(sz):
		var ty := y / tile
		var yo := (ty % 2) * (tile / 2)
		for x in range(sz):
			var tx := (x + yo) / tile
			var v := 0.9 if (tx + ty) % 2 == 0 else 0.7
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_lines() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var num_lines := 8
	var line_width := 3
	var gap := sz / num_lines
	for y in range(sz):
		var in_line := (y % gap) < line_width
		for x in range(sz):
			var v := 0.15 if in_line else 0.7
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_hexagon() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var hex_r := 30.0
	var w := hex_r * sqrt(3.0)
	var h := hex_r * 1.5
	var hs := 0.5 * sqrt(3.0)
	var line_w := 2.0

	for y in range(sz):
		for x in range(sz):
			var gx := int(floor(float(x) / w))
			var gy := int(floor(float(y) / h))
			var cx := (gx + 0.5) * w
			var cy := (gy + 0.5) * h
			if gy % 2 == 1:
				cx += w * 0.5

			var rx := abs(float(x) - cx)
			var ry := abs(float(y) - cy)
			var qx := rx / (hex_r * hs)
			var qy := ry / hex_r

			if qy < 1.0 and qx < 1.0 and qx * 0.5 + qy < 1.0:
				var d := min(1.0 - qx, min(1.0 - qy, 1.0 - (qx * 0.5 + qy)))
				var v := 0.15 if d * hex_r < line_w else 0.7
				img.set_pixel(x, y, Color(v, v, v, 1.0))
			else:
				img.set_pixel(x, y, Color(0.7, 0.7, 0.7, 1.0))

	return ImageTexture.create_from_image(img)


static func _make_diagonal() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cell := 64
	for y in range(sz):
		var cy := y / cell
		var ly := y % cell
		for x in range(sz):
			var cx := x / cell
			var lx := x % cell
			var diag := ly < lx
			var light := (cx + cy) % 2 == 0
			var v := 0.9 if light == diag else 0.7
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_triangles() -> Texture2D:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cell := 48
	var line_w := 2

	for y in range(sz):
		var cy := y / cell
		var ly := y - cy * cell
		for x in range(sz):
			var cx := x / cell
			var lx := x - cx * cell

			var on_edge := lx < line_w or ly < line_w or lx >= cell - line_w or ly >= cell - line_w
			var on_diag1 := abs(ly - lx) < line_w
			var on_diag2 := abs(ly - (cell - 1 - lx)) < line_w

			var tri := 0
			if ly < lx and ly < cell - 1 - lx:
				tri = 0
			elif lx >= cell - 1 - lx and lx > ly:
				tri = 1
			elif ly >= lx and ly >= cell - 1 - lx:
				tri = 2
			else:
				tri = 3

			if on_edge or on_diag1 or on_diag2:
				img.set_pixel(x, y, Color(0.15, 0.15, 0.15, 1.0))
			else:
				var light := (cx + cy + tri) % 2 == 0
				var v := 0.9 if light else 0.7
				img.set_pixel(x, y, Color(v, v, v, 1.0))

	return ImageTexture.create_from_image(img)


static func get_preset_names() -> PackedStringArray:
	var names: Array[String] = []
	for key in PRESETS.keys():
		if key != "Basic":
			names.append(key)
	names.sort()
	names.insert(0, "Basic")
	return PackedStringArray(names)
