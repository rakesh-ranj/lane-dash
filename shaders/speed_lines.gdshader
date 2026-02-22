shader_type canvas_item;

// Radial speed lines emanating from the center of the screen.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float line_count : hint_range(8.0, 64.0) = 24.0;
uniform float line_width : hint_range(0.001, 0.05) = 0.015;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.3;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float scroll_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	// Radial lines pattern.
	float line_pattern = abs(sin(angle * line_count + TIME * scroll_speed));
	float line_mask = smoothstep(line_width, 0.0, 1.0 - line_pattern);

	// Fade out toward center, full strength at edges.
	float radial_fade = smoothstep(inner_radius, 0.7, dist);

	// Combine.
	float alpha = line_mask * radial_fade * intensity * line_color.a;
	COLOR = vec4(line_color.rgb, alpha);
}
