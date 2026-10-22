shader_type canvas_item;
render_mode unshaded;

// Near parallax layers: luminance grade, screen-space shadow tint, self glow.
global uniform vec2 camera_pan;

uniform sampler2D layer_tex : repeat_enable, filter_nearest;
uniform sampler2D glow_tex : repeat_enable, filter_linear;
uniform sampler2D grade : filter_linear;
uniform vec2 tex_size = vec2(320.0, 180.0);
uniform float texel_px = 6.0;
uniform float zoom = 1.0;
uniform float speed = 0.25;
uniform vec2 layer_offset = vec2(0.0);

uniform float grade_gain = 3.6;
uniform float opacity = 1.0;

uniform float glow_threshold = 0.10;
uniform float glow_radius = 0.5;
uniform float glow_strength = 1.2;
uniform vec3 glow_color : source_color = vec3(0.35, 0.06, 0.20);

uniform vec3 shadow_color : source_color = vec3(0.90, 1.30, 0.40);
uniform vec2 shadow_center = vec2(0.95, 0.55);
uniform float shadow_radius = 1.05;
uniform float shadow_strength = 0.70;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float luma(vec3 c) {
	return dot(c, LUMA);
}

vec2 art_uv(vec2 uv, vec2 texel_shift) {
	vec2 p = (uv - 0.5) * tex_size / zoom + tex_size * 0.5;
	p += camera_pan * speed / (texel_px * zoom) + layer_offset * tex_size + texel_shift;
	return p / tex_size;
}

float bright_of(vec2 uv, vec2 shift) {
	vec4 s = texture(glow_tex, art_uv(uv, shift));
	return s.a * max(luma(s.rgb) * grade_gain - glow_threshold, 0.0);
}

void fragment() {
	vec4 s = texture(layer_tex, art_uv(UV, vec2(0.0)));
	vec3 col = texture(grade, vec2(clamp(luma(s.rgb) * grade_gain, 0.0, 1.0), 0.5)).rgb;

	float r = glow_radius;
	float g = bright_of(UV, vec2(r, 0.0)) + bright_of(UV, vec2(-r, 0.0));
	g += bright_of(UV, vec2(0.0, r)) + bright_of(UV, vec2(0.0, -r));
	g += bright_of(UV, vec2(r, r) * 0.7071) + bright_of(UV, vec2(-r, r) * 0.7071);
	g += bright_of(UV, vec2(r, -r) * 0.7071) + bright_of(UV, vec2(-r, -r) * 0.7071);
	g = g / 8.0;

	col += glow_color * g * glow_strength;

	float sm = smoothstep(shadow_radius, 0.0, distance(UV, shadow_center));
	// Tint only the shadowed faces; highlights must stay plum like the reference.
	float lit = smoothstep(0.25, 0.55, max(col.r, max(col.g, col.b)));
	col *= mix(vec3(1.0), shadow_color, sm * shadow_strength * (1.0 - lit));

	float a = max(s.a, g * glow_strength);
	COLOR = vec4(col, clamp(a, 0.0, 1.0) * opacity);
}
