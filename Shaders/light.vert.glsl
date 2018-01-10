#version 450

in vec2 pos;

uniform mat4 mproj;
uniform vec2 cpos;
uniform float radius;

out vec2 rel;
out float reld;

void kore(){
	gl_Position = mproj * vec4(pos, 0, 1);
	rel = vec2(pos.x,pos.y) - cpos;
	reld = radius;
}