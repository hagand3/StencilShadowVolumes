//Description:
//Simply tests if the vertex is facing the light or not. 
//If facing away, extrude vertex along vector pointing from light source to vertex
//Recall that each silhouette edge found in the original geometry is constructed into a shadow volume quad
//Assuming a quad of 4 vertices, Shadow Volume quads contain vertices V1_na, V2_na, V2_nb, and V1_nb
//V1 and V2 are the (x,y,z) positions of vertex 1 and 2 making up the silhouette edge.
//na and nb denote the normals of triangle a and triangle b which share the edge formed by V1 and V2.
//The normals stored in the vertex correspond to either triangle a or triangle b, 
//Whichever triangle is facing away from the light source is extruded away.
//If both triangles are facing away, the entire edge quad is extruded away.
//This may seem inefficient, but this arrangement is incredibly robust and allows for similar instructions for light/dark caps (Read below)

//Light/Dark caps are duplicated model geometry required for the depth-fail / z-fail technique.
//Light caps face the light while dark caps face away, and are thus extruded away in the same manner described above.
//These caps ensure that if the camera resides inside a shadow volume, the stencil buffer will count correctly

attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;					// normal (nx,ny,nz)
attribute vec4 in_Colour;					

uniform vec3 LightPos; //position of the light source
uniform vec3 LightCol; //rgb color of light
uniform float extrusion_distance; //distance to extrude shadow volume by. Sufficiently large to extrude shadow volumes but not too large (will lead to precision issues)

const float _pi = 3.1415;

void main()
{
	vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position.xyz,1.0); //translate/rotate position according to world matrix
	vec4 normA = normalize(gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0)); //translate/rotate normals according to world matrix

	vec3 LightDirec = normalize(pos.xyz - LightPos); //calculate light direction unit vector
	float LdotA = dot(LightDirec,normA.xyz); //calculate dot product of light direction unit vector and normal to determine if vertex is facing towards or away from light source
	float extrudeCondition = step(0.0, LdotA); //0.0 if facing toward light, 1.0 if facing away
	pos.xyz += extrusion_distance*LightDirec*extrudeCondition; //extrude along light direction towards "infinity" only if facing away from light
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*pos;
}