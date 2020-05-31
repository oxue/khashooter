#version 450

in vec2 pos;

uniform mat4 mproj;
uniform vec2 cpos;
uniform float radius;

out vec2 pos2;
out vec3 lightPosition;
out float l_radius;

void kore(){
	gl_Position = mproj * vec4(pos, 0, 1);
	lightPosition = vec3(cpos.x, cpos.y, radius);
	pos2 = pos;
	l_radius = radius;
}