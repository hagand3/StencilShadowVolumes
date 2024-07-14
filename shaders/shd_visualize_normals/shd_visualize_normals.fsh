varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNorm;

void main()
{
	vec3 ColNorm = normalize(v_vNorm*0.5+0.5); //convert normals to rgb
	vec4 Base = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord ); //get base texture
	vec4 Col = vec4(vec3(mix(Base.rgb,ColNorm,0.75)),1.0); //mix to display mostly normal but a little bit of texture
	gl_FragColor = Col;
}
