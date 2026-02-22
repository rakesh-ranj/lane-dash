shader_type spatial;
render_mode unshaded;

// Pulsing glow effect for obstacle highlighting.
uniform vec4 glow_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float min_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float max_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	float pulse = mix(min_intensity, max_intensity,
		(sin(TIME * pulse_speed * TAU) + 1.0) * 0.5);
	ALBEDO = glow_color.rgb * pulse;
	ALPHA = glow_color.a * pulse;
	EMISSION = glow_color.rgb * pulse * 0.5;
}
