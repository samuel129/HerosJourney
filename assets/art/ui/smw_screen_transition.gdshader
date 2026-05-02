shader_type canvas_item;

uniform float luminance_cutoff: hint_range(0.0, 1.0) = 0.0;
uniform bool invert = false;

uniform sampler2D mask_texture;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	vec4 sample_color = texture(mask_texture, UV);
	float luminance = dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722));

	bool filter = luminance > luminance_cutoff;
	if (invert) {
		filter = !filter;
	}

	vec4 screen_col = texture(screen_texture, SCREEN_UV);

	if (filter) {
		COLOR = screen_col;
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, 1.0); // or transparent if you prefer
	}
}