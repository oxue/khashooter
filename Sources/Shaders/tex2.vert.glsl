attribute vec2 pos;
attribute vec2 uv;
uniform mat4 mproj;
varying vec2 tuv;

void kore(){
	gl_Position = mproj * vec4(pos, 0, 0);
	tuv = uv;
}