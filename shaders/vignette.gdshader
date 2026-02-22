shader_type canvas_item;

// Screen edge darkening + red flash on collision.
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 0.5);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 2.0;

	// Standard dark vignette.
	float vignette = smoothstep(1.0 - vignette_softness, 1.0, dist);
	vec4 vig = vec4(vignette_color.rgb, vignette * vignette_intensity);

	// Red flash overlay (uniform across screen, fades via flash_intensity).
	vec4 flash = vec4(flash_color.rgb, flash_intensity * flash_color.a);

	// Blend: additive for flash, overlay for vignette.
	float final_alpha = max(vig.a, flash.a);
	vec3 final_color = mix(vig.rgb, flash.rgb, flash.a / max(final_alpha, 0.001));
	COLOR = vec4(final_color, final_alpha);
}
