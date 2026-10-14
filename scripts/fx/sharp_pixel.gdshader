// sharp_pixel.gdshader: the "sharp pixel" filter for grid pixel art (GDD §15.0
// "Art pass grid: 1 art px = 1 screen px"). Grid art is drawn 1:1 at the
// 1280x720 layout, but the window stretches that layout (a 1920x1080 window is
// x1.5, Zoom Close x2), so one art pixel often covers a fractional number of
// screen pixels. Plain nearest filtering then draws some art pixels 1 px wide
// and others 2 px (uneven, shimmering in motion); plain linear filtering blurs.
// This shader samples the LINEAR-filtered texture at the nearest texel centre
// everywhere except a thin band at each texel edge, `edge_softness` screen px
// wide, where it blends to the neighbour: every art pixel looks the same size
// and stays crisp. SpriteBank puts it on any CanvasItem that draws grid art
// (SpriteBank.apply_sharp()). When a texture is drawn smaller than its texels
// (legacy 3x placeholders, minified icons) it falls back to plain linear
// sampling, so other art drawn by the same node looks exactly as before. The
// fallback is decided per axis, so the tile seams of the UI kit's tiled 9-slice
// frames (UiTheme) stay crisp.
// Untextured shapes sample Godot's white default texture: unchanged too.
shader_type canvas_item;

// Width (screen px) of the blend at each art-pixel edge. 0 = nearest (uneven at
// fractional scales), 1 = soft. Set from SpriteData.SHARP_EDGE_SOFTNESS.
uniform float edge_softness = 0.5;

// Vertex colour of the draw call (modulate, the caller's tint, the hit flash),
// carried to the fragment stage, which re-samples the texture itself.
varying vec4 vertex_colour;

void vertex() {
	vertex_colour = COLOR;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));  // Texture size (texels).
	vec2 pix = UV * size;  // Position in texels.
	vec2 per_px = fwidth(pix);  // Texels covered by one screen px (< 1 = magnified).
	vec2 corner = floor(pix + 0.5);  // Nearest texel corner (between two texel centres).
	vec2 band = max(per_px * edge_softness, vec2(1e-4));  // Blend band (texels).
	vec2 sharp = corner + clamp((pix - corner) / band, -0.5, 0.5);  // Sharp-pixel sample position.
	// Per axis: an axis drawn smaller than its texels (minified) samples plainly
	// (linear) along that axis. Decided per axis so the seams of a tiled 9-slice
	// UI frame (where the texel coordinate jumps along one axis) do not blur its
	// 1-texel rings along the other; a uniformly scaled sprite behaves as before
	// (both axes sharp, or both plain).
	pix = mix(sharp, pix, step(vec2(1.01), per_px));
	COLOR = texture(TEXTURE, pix / size) * vertex_colour;
}
