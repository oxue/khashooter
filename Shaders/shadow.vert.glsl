#version 450

in vec2 pos;
in vec2 settings;
in vec2 coords;

out float penumbraFlag;
out vec2 pcoords;

smooth out vec2 pos2;
out vec3 lightPosition;

uniform mat4 mproj;
uniform vec2 cpos;

void main(){
	float sourceRadius = 10; // replace this with uniform
	float castRadius = 300; // replace this with uniform
	
	float penumbraOffsetFlag = abs(settings.y) - 1;
	float extendLineFlag = settings.x;
	vec2 lightDirection = normalize(pos.xy - cpos);
	vec2 lightLeftHand = vec2(lightDirection.y, -lightDirection.x);
	vec2 lightPoint = cpos + lightLeftHand * penumbraOffsetFlag * sourceRadius;
	
	vec2 castDirection = normalize(pos.xy - lightPoint);
	castDirection = castDirection * extendLineFlag * castRadius + pos.xy;
	
	gl_Position = mproj * vec4(castDirection.x, castDirection.y, 0, 1);
	
	//outputs
	penumbraFlag = settings.y;
	pcoords = coords;

	lightPosition = vec3(cpos.x, cpos.y, 64);
	pos2 = castDirection;
}