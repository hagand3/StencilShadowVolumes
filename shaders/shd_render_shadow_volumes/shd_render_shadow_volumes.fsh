uniform vec3 LightCol; //color of light

void main()
{
	gl_FragColor = vec4(LightCol,0.5); //color here only used in debug visualization
}