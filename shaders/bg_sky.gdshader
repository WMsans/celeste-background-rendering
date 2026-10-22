shader_type canvas_item;
render_mode unshaded;

// Desktop sky: flat gold gradient with the pack's bg0 cloud bands as a mask.
global uniform vec2 camera_pan;

uniform sampler2D cloud_tex : repeat_enable, filter_nearest;
uniform sampler2D base_gradient : filter_linear;
uniform vec2 tex_size = vec2(320.0, 180.0);
uniform float texel_px = 6.0;
uniform float zoom = 1.0;
uniform float speed = 0.02;
uniform vec2 cloud_offset = vec2(0.0);

uniform float mask_lo = 0.345;
uniform float mask_hi = 0.500;
uniform vec3 cloud_tint : source_color = vec3(0.98, 0.90, 0.80);

uniform vec3 sun_color : source_color = vec3(1.0, 0.68, 0.22);
uniform vec2 sun_uv = vec2(0.72, 0.92);
uniform float sun_radius = 0.55;
uniform float sun_strength = 0.05;

uniform vec3 wash_color : source_color = vec3(1.0, 0.70, 0.20);
uniform float wash_strength = 0.02;
uniform float wash_start = 0.55;

uniform vec3 rim_color : source_color = vec3(1.0, 0.86, 0.55);
uniform float rim_strength = 0.02;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float luma(vec3 c) {
	return dot(c, LUMA);
}

vec2 cloud_uv(vec2 uv) {
	vec2 p = (uv - 0.5) * tex_size / zoom + tex_size * 0.5;
	p += camera_pan * speed / (texel_px * zoom) + cloud_offset * tex_size;
	return p / tex_size;
}

float mask_of(vec2 uv) {
	// Blur the mask so the pack's star grain does not read as 6 px noise.
	vec2 p = cloud_uv(uv) * tex_size;
	float l = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			l += luma(texture(cloud_tex, (p + vec2(float(x), float(y)) * 2.0) / tex_size).rgb);
		}
	}
	return smoothstep(mask_lo, mask_hi, l / 9.0);
}

void fragment() {
	vec2 uv = UV;
	vec3 base = texture(base_gradient, vec2(clamp(uv.y, 0.0, 1.0), 0.5)).rgb;

	float m = mask_of(uv);
	vec3 col = mix(base, base * cloud_tint, m);

	col += sun_color * smoothstep(sun_radius, 0.0, distance(uv, sun_uv)) * sun_strength;
	col += wash_color * smoothstep(wash_start, 1.0, uv.y) * wash_strength;

	// Lift cloud edges so the post bloom catches them.
	vec2 px = SCREEN_PIXEL_SIZE * 2.5;
	float dx = mask_of(uv + vec2(px.x, 0.0)) - mask_of(uv - vec2(px.x, 0.0));
	float dy = mask_of(uv + vec2(0.0, px.y)) - mask_of(uv - vec2(0.0, px.y));
	col += rim_color * smoothstep(0.04, 0.30, length(vec2(dx, dy))) * rim_strength;

	COLOR = vec4(col, 1.0);
}
