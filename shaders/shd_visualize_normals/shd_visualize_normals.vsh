//Visualize normals as color
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNorm;

void main()
{
	vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position,1.0); //translate/rotate position according to world matrix
    vec4 Norm = normalize(gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0)); //translate/rotate normals according to world matrix
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * gm_Matrices[MATRIX_VIEW] * pos;
    
	v_vNorm = Norm.xyz;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
