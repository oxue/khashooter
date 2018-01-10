#version 450

in vec3 pos;

uniform mat4 mproj;
uniform vec2 cpos;

void main(){
	vec2 v0 = pos.xy - cpos;
	v0 = normalize(v0);
	v0 = v0 * pos.z * 200.0 + pos.xy;
	gl_Position = mproj * vec4(v0.x, v0.y, 0, 1);
}