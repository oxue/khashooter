#version 450

in vec2 pos;
in vec2 settings;
in vec2 coords;

out float penumbraFlag;
out vec2 pcoords;

smooth out vec2 pos2;
out vec3 lightPosition;

uniform mat4 mproj;
uniform vec2 camera_position;
uniform vec2 cpos;
uniform float sourceRadius = 15;

void main(){
	float castRadius = 600; // replace this with uniform
	float penumbraOffsetFlag = abs(settings.y) - 1;
	float extendLineFlag = settings.x;
	vec2 camera_space_pos = pos.xy - camera_position;

	vec2 light_center_pos = cpos - camera_position;
	vec2 lightDirection = normalize(camera_space_pos.xy - light_center_pos);
	vec2 lightLeftHand = vec2(lightDirection.y, -lightDirection.x);
	vec2 lightPoint = light_center_pos + lightLeftHand * penumbraOffsetFlag * sourceRadius;
	
	vec2 castDirection = normalize(camera_space_pos.xy - lightPoint);
	
	castDirection = castDirection * extendLineFlag * castRadius + camera_space_pos.xy;
	
	gl_Position = mproj * vec4(castDirection.x, castDirection.y, 0, 1);
	
	//outputs
	penumbraFlag = settings.y;
	pcoords = coords;

	lightPosition = vec3(light_center_pos.x, light_center_pos.y, 64);
	pos2 = castDirection;
}