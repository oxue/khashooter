precision mediump float;

uniform sampler2D tex;
varying vec2 tuv;
void kore(){
	gl_FragColor = texture2D(tex,tuv);
}