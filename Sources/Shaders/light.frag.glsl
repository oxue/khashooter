precision mediump float;

uniform vec4 color;

varying vec2 rel;
varying float reld;

void kore(){
	vec4 t = color * ( 1.0 - pow(length(rel),.5) / pow(reld,.5));
	
    gl_FragColor = clamp(t,vec4(0,0,0,0),vec4(1,1,1,1));
}