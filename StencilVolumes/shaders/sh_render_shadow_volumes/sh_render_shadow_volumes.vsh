//
// Shadow Volumes shader with movement for dynamic tiles
// Extrudable vertices are encoded with -x and -y (x and y should never be less than 0 in worldspace)
//precision lowp int;

attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;
attribute vec3 in_Normal1;
attribute vec4 in_Colour;                  // (x,y,z)     Normal from face A
//attribute vec4 in_Colour1;                  // (x,y,z)     Normal from face B

uniform vec3 LightPos;

const float _pi = 3.1415;
const float large_val = 100.0;

void main()
{
	vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position.xyz,1.0); //translate/rotate according to world matrix
	//vec4 normA = normalize(gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0)); //translate/rotate according to world matrix

	vec4 normA = vec4(in_Normal,0.0);
	vec3 LightDirec = normalize(pos.xyz - LightPos);
	float LdotA = dot(LightDirec,normA.xyz);
	float ExtrudeA = step(0.0, LdotA); 
    float extrudeCondition = ExtrudeA;
	
    pos.xyz += large_val*LightDirec*extrudeCondition; //extrude along light direction towards infinity
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*pos;
}