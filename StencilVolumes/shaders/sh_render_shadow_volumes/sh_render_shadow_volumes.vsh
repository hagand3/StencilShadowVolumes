//
// Shadow Volumes shader with movement for dynamic tiles
// Extrudable vertices are encoded with -x and -y (x and y should never be less than 0 in worldspace)
//precision lowp int;

attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour0;                  // (x,y,z)     Normal from face A
attribute vec4 in_Colour1;                  // (x,y,z)     Normal from face B

uniform vec3 LightDirec;

const float _pi = 3.1415;
const float large_val = 100000000000000000000000000000000000.0;

void main()
{
    vec3 NA = in_Colour0.rgb;
    vec3 NB = in_Colour1.rgb;
    vec3 normA = (NA*2.0-1.0);
    vec3 normB = (NB*2.0-1.0);
    float LdotA = dot(LightDirec,normA);
    float LdotB = dot(LightDirec,normB);
    vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position.xyz,1.0);
    
    //Determine which vertices to extrude
    float SilEdge = 1.0 - step(0.0,LdotA*LdotB); //returns 1.0 if LdotA*LdotB < 0, 0.0 otherwise
	float ExtrudeA = step(0.0, LdotA) * SilEdge; 
    float ExtrudeB = step(0.0, LdotB) * SilEdge;
    float MobileVertexA = step(0.5,in_Colour0.a);
    float MobileVertexB = step(0.5,in_Colour1.a);
    float extrudeCondition = ExtrudeA*MobileVertexA + ExtrudeB*MobileVertexB;
    
    pos.xyz += large_val*LightDirec*extrudeCondition; //extrude along light direction towards infinity
	//pos += 0.1*(normA+normB)*extrudeCondition;
    //gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos,1.0);
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*pos;
}