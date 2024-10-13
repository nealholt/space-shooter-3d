shader_type spatial;
// Tutorial source:
// https://docs.godot.community/tutorials/shaders/your_first_shader/your_first_3d_shader.html#setting-up

// My idea was to create a prism / crystal for embedding
// in asteroids to add some color.

uniform float height_scale = 0.5;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 tex_position;

void vertex() {
	// Only apply transformation to the top vertices
	// around edges
	if (VERTEX.y == 0.5 && (abs(VERTEX.x) == 0.5 || abs(VERTEX.z) == 0.5))
	{
		tex_position = VERTEX.xz / 2.0 + 0.5;
		float height = texture(noise, tex_position).x;
		VERTEX.y += height * height_scale;
	}
}

void fragment() {
	// Called for every pixel the material is visible on.
	NORMAL_MAP = texture(normalmap, tex_position).xyz;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}