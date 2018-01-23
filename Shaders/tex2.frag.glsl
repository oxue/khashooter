#version 450

precision mediump float;

uniform sampler2D tex;
uniform sampler2D normalmap;

in vec2 tuv;
out vec4 fragmentColor;
void main(){	
    fragmentColor = texture(normalmap, tuv);
}