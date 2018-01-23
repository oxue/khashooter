#version 450

uniform vec4 color;

uniform sampler2D normalmap;

in vec2 pos2;
in vec3 lightPosition;

out vec4 fragColor;

void main(){
	vec3 pixelPos = vec3(pos2.x, pos2.y, 0);
	vec3 lightDirection = lightPosition - pixelPos;
	vec4 n = texture(normalmap, vec2(pos2.x/400, pos2.y/300));
	vec3 normal = vec3(n.x,n.y,n.z) * 2 - vec3(1,1,1);
	normal = normal/length(normal);
	
	float lightDistance = length(lightDirection);
	vec3 lightDirUnit = lightDirection / lightDistance;
	float dp = dot(lightDirUnit, normal);
	float reflection = dp < 0 ? 0 : dp;
	float f = lightDistance / 100;
	float attenuation = 1 / (f * f);

	fragColor = vec4(color.xyz * attenuation, 1);// * reflection;
}