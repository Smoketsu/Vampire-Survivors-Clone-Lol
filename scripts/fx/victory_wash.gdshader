// Victory wash: the last stand's full-screen pass (LastStand, content wave 2).
// It reads what is already on screen (the frozen world and the HUD under it),
// drains its colour by `desaturate` and washes it toward `gold_color` by `gold`.
// Purely visual; nothing reads it back.
shader_type canvas_item;

// The screen drawn so far (nearest filtering keeps the pixel art crisp).
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// Share of grey (0 = full colour, 1 = grey).
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
// Share of the gold wash (0 = none, 1 = fully gold-tinted).
uniform float gold : hint_range(0.0, 1.0) = 0.0;
// Colour of the wash.
uniform vec4 gold_color : source_color = vec4(1.0, 0.78, 0.36, 1.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(c, vec3(l), desaturate);
	// Tint by the gold (a multiply that lifts the darks a little, so it reads as light).
	vec3 tint = g * mix(vec3(1.0), gold_color.rgb * 1.3, gold) + gold_color.rgb * gold * 0.12;
	COLOR = vec4(tint, 1.0);
}
