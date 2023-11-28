#version 450

out vec4 fragmentColor;

in vec2 pcoords;
in float penumbraFlag;

in vec2 pos2;
in vec3 lightPosition;

uniform vec4 color;

void main(){	
    float val = 0;
    if(penumbraFlag == 1){
        val = 1;
    }else{
        vec3 pixelPos = vec3(pos2.x, pos2.y, 0);
        vec3 lightDirection = lightPosition - pixelPos;
        float lightDistance = length(lightDirection);
        float f = lightDistance / 100;
        float attenuation = 1 / (f * f);
        val =  (pcoords.x / sqrt(pcoords.y));
    }
    fragmentColor = vec4(0,0,0,val);
}