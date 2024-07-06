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
const float large_val = 100000000000000000000000000000000000.0;

void main()
{
    //vec3 NA = in_Colour0.rgb;
    //vec3 NB = in_Colour1.rgb;
    //vec4 normA = gm_Matrices[MATRIX_WORLD]*vec4((NA*2.0-1.0),0.0);
    //vec4 normB = gm_Matrices[MATRIX_WORLD]*vec4((NB*2.0-1.0),0.0);
	vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position.xyz,1.0);
	vec4 normA = gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0);
	vec4 normB = gm_Matrices[MATRIX_WORLD]*vec4(in_Normal1,0.0);
	//vec4 normA = vec4(in_Normal,0.0);
	//vec4 normB = vec4(in_Normal1,0.0);
    
	//vec3 LightDirec = normalize(pos.xyz - vec3(0.0,0.0,-800.0));
	vec3 LightDirec = normalize(pos.xyz - LightPos);
	//vec3 LightDirec = LightPos;
	float LdotA = dot(LightDirec,normA.xyz);
    //float LdotB = dot(LightDirec,normB.xyz);
    
    //Determine which vertices to extrude
    //float SilEdge = 1.0 - step(0.0,LdotA*LdotB); //returns 1.0 if LdotA*LdotB < 0, 0.0 otherwise
	//float ExtrudeA = step(0.0, LdotA) * SilEdge; 
    //float ExtrudeB = step(0.0, LdotB) * SilEdge;
    //float MobileVertexA = step(0.5,in_Colour.r);
    //float MobileVertexB = step(0.5,in_Colour.g);
    //float extrudeCondition = ExtrudeA*MobileVertexA + ExtrudeB*MobileVertexB;
	
	//Method 2
	float ExtrudeA = step(0.0, LdotA); 
    float extrudeCondition = ExtrudeA;
	
    pos.xyz += large_val*LightDirec*extrudeCondition; //extrude along light direction towards infinity
	//pos += 0.1*(normA+normB)*extrudeCondition;
    //gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos,1.0);
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*pos;
}