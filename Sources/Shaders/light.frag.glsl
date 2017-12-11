#version 450

uniform vec4 color;

in vec2 rel;
in float reld;

out vec4 fragColor;

void main(){
	vec4 t = color * ( 1.0 - pow(length(rel),.5) / pow(reld,.5));
	
    fragColor = clamp(t,vec4(0,0,0,0),vec4(1,1,1,1));
}