shader_type spatial;
render_mode blend_mix;

uniform sampler2D u_albedo : source_color;
uniform float u_saturation = 1.0;
uniform float u_hue_shift = 0.0;
uniform float u_sharpness = 0.0;
uniform float u_brightness = 1.0;
uniform float u_contrast = 1.0;

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 color = texture(u_albedo, DECAL_UV);

	if (u_sharpness > 0.001) {
		vec4 blur = textureLod(u_albedo, DECAL_UV, u_sharpness * 5.0);
		float f = 1.0 + u_sharpness * 0.5;
		color = mix(blur, color, f);
	}

	vec3 hsv = rgb_to_hsv(color.rgb);
	hsv.x = fract(hsv.x + u_hue_shift);
	hsv.y *= u_saturation;
	color.rgb = hsv_to_rgb(hsv);

	color.rgb = (color.rgb - 0.5) * u_contrast + 0.5 + u_brightness - 1.0;

	ALBEDO = color.rgb;
	ALPHA = color.a;
}
