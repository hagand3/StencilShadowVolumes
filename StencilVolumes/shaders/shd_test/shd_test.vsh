//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNorm;

uniform mat4 t_Matrix; 

void main()
{
	vec4 pos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position,1.0);
    vec4 Norm = normalize(gm_Matrices[MATRIX_WORLD]*vec4(in_Normal,0.0));
	// vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * gm_Matrices[MATRIX_VIEW] * pos;
    
	v_vNorm = Norm.xyz;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
