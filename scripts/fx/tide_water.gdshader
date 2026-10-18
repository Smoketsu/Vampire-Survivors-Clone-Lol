// The tide of Gullhaven Harbour (TideDirector, HarbourStage.TIDE): one big
// rect around the necromancer whose fragments compute the SAME water test as
// TideDirector.depth() on the CPU, so what is drawn is what slows. A point is
// under water while its "depth" s > 0:
//   normal   s = level - h(p), h(p) = 0.5 + sum amp * sin(p.x kx + p.y ky + phase)
//   seawall  s = min(px_to_h * (|p.y - strip_y| - strip_half), island_level - h(p))
//   surge    the band behind the wave front is flooded (s >= surge_depth)
//   piers    always dry (s <= -pier_depth)
// Drawn in pixel-art style: world positions are snapped to an `art_px` grid,
// flat colours in three bands (foam line, shallows, deep water), sparse moonlit
// glints that drift with TIME (purely visual), the seawall's stone lip and the
// surge's telegraph and crest. GL Compatibility safe.
shader_type canvas_item;

// Waves of the height field: (kx, ky, phase, amp) each (HarbourStage.TIDE "field").
uniform vec4 waves[4];
// Tide level (h units, 0..1): ground lower than this is flooded.
uniform float level = 0.2;
// 1 = the Seawall zone (a dry strip along x), 0 = the open town.
uniform float seawall_on = 0.0;
// World y (px) of the dry strip's centre line.
uniform float strip_y = 0.0;
// Half width (px) of the dry strip.
uniform float strip_half = 230.0;
// World y (px) of the sea edge of the seawall (the stone lip is drawn there).
uniform float wall_y = 230.0;
// Ground higher than this stays dry in the Seawall zone (islands).
uniform float island_level = 0.8;
// h units per px used to compare the strip distance with the height field.
uniform float px_to_h = 0.002;
// Surge: 0 none, 1 telegraph, 2 sweeping, 3 lingering (flooded band).
uniform float surge_state = 0.0;
// Surge band centre (world px), sweep direction (unit), half width and half length (px).
uniform vec2 surge_center = vec2(0.0);
uniform vec2 surge_dir = vec2(1.0, 0.0);
uniform float surge_half_width = 120.0;
uniform float surge_half_length = 750.0;
// Distance (px) of the wave front along the band from its centre.
uniform float surge_front = -750.0;
// 0..1 strength of the lingering surge water (fades out at its end).
uniform float surge_fade = 1.0;
// Up to 4 dry piers: (centre x, centre y, dir x, dir y) and (half length, half width, on, 0).
uniform vec4 pier_a[4];
uniform vec4 pier_b[4];
// Colours (HarbourStage.TIDE).
uniform vec4 water_color : source_color = vec4(0.05, 0.16, 0.18, 0.78);
uniform vec4 deep_color : source_color = vec4(0.03, 0.09, 0.12, 0.88);
uniform vec4 foam_color : source_color = vec4(0.62, 0.78, 0.74, 0.55);
uniform vec4 glint_color : source_color = vec4(0.55, 0.85, 0.8, 0.35);
uniform vec4 surge_color : source_color = vec4(0.6, 0.92, 0.86, 0.85);
// Stone lip of the seawall.
uniform vec4 wall_color : source_color = vec4(0.36, 0.38, 0.38, 1.0);
uniform vec4 wall_ink : source_color = vec4(0.06, 0.08, 0.1, 1.0);
// World px per drawn pixel (the pixel-art grid of the water).
uniform float art_px = 2.0;
// 1 = Reduced effects (no glints), 0 = Full.
uniform float reduced = 0.0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Ground height of world point p (TideDirector.height()).
float height(vec2 p) {
	float h = 0.5;
	for (int i = 0; i < 4; i++) {
		h += waves[i].w * sin(p.x * waves[i].x + p.y * waves[i].y + waves[i].z);
	}
	return h;
}

// Water depth of p before the surge and the piers (TideDirector._base_depth()).
float base_depth(vec2 p, float h) {
	if (seawall_on > 0.5) {
		float strip = px_to_h * (abs(p.y - strip_y) - strip_half);
		return min(strip, island_level - h);
	}
	return level - h;
}

void fragment() {
	vec2 p = floor(world / art_px) * art_px + art_px * 0.5;  // Snapped to the water's pixel grid.
	float h = height(p);
	float s = base_depth(p, h);
	// Surge band (local axes).
	vec2 rel = p - surge_center;
	float along = dot(rel, surge_dir);
	float across = dot(rel, vec2(-surge_dir.y, surge_dir.x));
	bool in_band = abs(across) <= surge_half_width && abs(along) <= surge_half_length;
	if (in_band && surge_state > 1.5) {
		bool behind = surge_state > 2.5 || along <= surge_front;
		if (behind) {
			s = max(s, 0.02 * surge_fade);
		}
	}
	// Piers stay dry.
	for (int i = 0; i < 4; i++) {
		if (pier_b[i].z > 0.5) {
			vec2 q = p - pier_a[i].xy;
			float pa = dot(q, pier_a[i].zw);
			float pc = dot(q, vec2(-pier_a[i].w, pier_a[i].z));
			if (abs(pa) <= pier_b[i].x && abs(pc) <= pier_b[i].y) {
				s = -1.0;
			}
		}
	}
	vec4 col = vec4(0.0);
	if (s > 0.0) {
		col = s > 0.06 ? deep_color : water_color;
		if (s < 0.008) {
			col = foam_color;  // The waterline.
		} else if (reduced < 0.5) {
			// Sparse moonlit glints drifting with the swell (visual only).
			float g = sin(p.x * 0.11 + TIME * 1.3) * sin(p.y * 0.17 - TIME * 0.9) * sin((p.x + p.y) * 0.05 + TIME * 0.4);
			if (g > 0.82) {
				col = mix(col, glint_color, glint_color.a);
				col.a = max(col.a, water_color.a);
			}
		}
	}
	// The seawall's stone lip along its sea edge (only where the strip is dry).
	if (seawall_on > 0.5) {
		float dw = p.y - wall_y;
		if (dw > -8.0 && dw <= 0.0) {
			col = dw > -2.0 ? wall_ink : wall_color;
		}
	}
	// Surge: telegraph (band outline and drifting chevrons) and the crest.
	if (in_band) {
		if (surge_state > 0.5 && surge_state < 1.5) {
			float edge = surge_half_width - abs(across);
			if (edge < 3.0) {
				col = mix(col, surge_color, 0.75);
				col.a = max(col.a, 0.75);
			} else {
				float chev = fract((along - abs(across) * 0.6) / 64.0 - TIME * 0.8);
				if (chev < 0.12) {
					col = mix(col, surge_color, 0.35);
					col.a = max(col.a, 0.3);
				}
			}
		} else if (surge_state > 1.5 && surge_state < 2.5) {
			float d = surge_front - along;
			if (d >= 0.0 && d < 16.0) {
				col = d < 6.0 ? surge_color : mix(water_color, surge_color, 0.6);
				col.a = max(col.a, 0.9);
			}
		}
	}
	COLOR = col;
}
