//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNorm;

void main()
{
	
	vec3 ColNorm = normalize(v_vNorm*0.5+0.5);
	vec4 Col = vec4(vec3(mix(v_vColour.rgb,ColNorm,1.0)),1.0);
    //gl_FragColor = Col * texture2D( gm_BaseTexture, v_vTexcoord );
	gl_FragColor = Col;
}
