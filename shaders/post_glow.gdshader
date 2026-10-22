shader_type canvas_item;
render_mode unshaded;

// Screen-space grade: warm bloom, ordered dither, vignette. Runs per output pixel.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

uniform float threshold = 0.85;
uniform float knee = 0.30;
uniform vec3 bloom_color : source_color = vec3(1.0, 0.74, 0.38);
uniform float bloom_strength = 0.35;
uniform float radius_a = 5.0;
uniform float radius_b = 16.0;
uniform float weight_a = 0.55;
uniform float weight_b = 0.45;

uniform float dither_strength = 1.0;
uniform float vignette_strength = 0.10;
uniform float vignette_start = 0.55;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

vec3 bright_pass(vec3 c) {
	vec3 b = max(c - vec3(threshold), vec3(0.0));
	return b * b / (b + vec3(knee));
}

vec3 ring(vec2 uv, vec2 px) {
	vec3 sum = vec3(0.0);
	sum += bright_pass(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb);
	sum += bright_pass(texture(screen_tex, uv - vec2(px.x, 0.0)).rgb);
	sum += bright_pass(texture(screen_tex, uv + vec2(0.0, px.y)).rgb);
	sum += bright_pass(texture(screen_tex, uv - vec2(0.0, px.y)).rgb);
	sum += bright_pass(texture(screen_tex, uv + px * 0.7071).rgb);
	sum += bright_pass(texture(screen_tex, uv - px * 0.7071).rgb);
	sum += bright_pass(texture(screen_tex, uv + vec2(px.x, -px.y) * 0.7071).rgb);
	sum += bright_pass(texture(screen_tex, uv + vec2(-px.x, px.y) * 0.7071).rgb);
	return sum / 8.0;
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	vec3 bloom = ring(SCREEN_UV, SCREEN_PIXEL_SIZE * radius_a) * weight_a
		+ ring(SCREEN_UV, SCREEN_PIXEL_SIZE * radius_b) * weight_b;
	col += bloom * bloom_color * bloom_strength;

	float v = smoothstep(vignette_start, 1.0, length((SCREEN_UV - 0.5) * 1.3));
	col *= 1.0 - vignette_strength * v;

	vec2 pixel = SCREEN_UV / SCREEN_PIXEL_SIZE;
	int bi = int(mod(pixel.x, 4.0)) + 4 * int(mod(pixel.y, 4.0));
	col += (BAYER[bi] / 16.0 - 0.5) * dither_strength / 255.0;

	COLOR = vec4(col, 1.0);
}
