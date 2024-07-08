//
// Shadow Volumes shader with movement for dynamic tiles
// Extrudable vertices are encoded with -x and -y (x and y should never be less than 0 in worldspace)
//precision lowp int;

attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;
attribute vec4 in_Colour;

uniform vec3 LightPos;

const float _pi = 3.1415;
const float large_val = 20.0; //1000000000.0;
//const float large_val = 10000000000000000000.0;

void main()
{
    vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position.xyz,1.0); //translate/rotate according to world matrix
	vec4 normA = normalize(gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0)); //translate/rotate according to world matrix
	//vec4 normA = vec4(in_Normal,0.0); //translate/rotate according to world matrix

	vec3 LightDirec = normalize(pos.xyz - LightPos);
	float LdotA = dot(LightDirec,normA.xyz);
	float extrudeCondition = step(0.0, LdotA); 
	
	//***FLAG "endcap" triangles with color attribute. If facing away from source, extrude as normal.
	//if facing light source, set position to -99999,-999999,-9999999 to cull it away.
	float cap_extrude_condition = step(0.5,in_Colour.r); 
	
	//pos.xyz -= 0.005*normA.xyz*(1.0-extrudeCondition); //if light-facing, extrude slightly away from own normal (***LEAVES CRACKS IN VOLUME. NO GOOD)
	//pos.xyz += 0.03*LightDirec*(1.0-extrudeCondition); //if light-facing, extrude slightly away from light source (***DOESNT ADDRESS FACES PARALLEL TO LIGHT SOURCE. NO GOOD)
	pos.xyz += large_val*LightDirec*extrudeCondition; //extrude along light direction towards infinity if facing away from light
	//if(cap_extrude_condition > 0.5 && extrudeCondition < 0.5) //if a non-edge triangle and facing the light, extrude with reverse winding
	//{
	//	pos.xyz += large_val*LightDirec;
	//}
	
	//if(cap_extrude_condition > 0.5 && extrudeCondition > 0.5)
	//{
	//	pos = vec4(0.0,0.0,-999999.0,1.0); //set to 0,0,-999999 (should be culled below visible geometry and since it has no fill)
	//}
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*pos;
}