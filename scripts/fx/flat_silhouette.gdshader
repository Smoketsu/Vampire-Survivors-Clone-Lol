// Flat silhouette of pixel art (the Codex's entries not met yet, CodexArt):
// every opaque texel is drawn in the draw call's modulate colour (rgb flat,
// alpha = texel alpha x modulate alpha), so a sprite becomes one solid
// shape. Sampling is the sharp-pixel rule of sharp_pixel.gdshader (crisp
// art pixels whose edges blend over `edge_softness` screen px), so the
// silhouette's edge matches the art exactly. GL Compatibility safe.
shader_type canvas_item;

// Width (screen px, 0-1) of the blend at each art-pixel edge (SpriteData.SHARP_EDGE_SOFTNESS).
uniform float edge_softness = 0.5;

// The draw call's modulate colour (the flat fill).
varying vec4 vertex_colour;

void vertex() {
	vertex_colour = COLOR;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));  // Texture size (texels).
	vec2 pix = UV * size;  // Position in texels.
	vec2 per_px = fwidth(pix);  // Texels covered by one screen px.
	vec2 corner = floor(pix + 0.5);  // Nearest texel corner.
	vec2 band = max(per_px * edge_softness, vec2(1e-4));  // Blend band (texels).
	vec2 sharp = corner + clamp((pix - corner) / band, -0.5, 0.5);  // Sharp-pixel sample position.
	pix = mix(sharp, pix, step(vec2(1.01), per_px));
	COLOR = vec4(vertex_colour.rgb, texture(TEXTURE, pix / size).a * vertex_colour.a);
}
