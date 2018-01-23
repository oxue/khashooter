#version 450

in vec2 pos;

uniform mat4 mproj;
uniform vec2 cpos;
uniform float radius;

out vec2 pos2;
out vec3 lightPosition;

void kore(){
	gl_Position = mproj * vec4(pos, 0, 1);
	lightPosition = vec3(cpos.x, cpos.y, 64);
	pos2 = pos;
}