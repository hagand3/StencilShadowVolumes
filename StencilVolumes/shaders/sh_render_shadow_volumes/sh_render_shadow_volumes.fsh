//Add to "stencil buffer" (increment if front-facing with red, decrement if back-facing with green)
//vec2 frontFacingColor = vec2(255.0/255.0, 0.0);
//vec2 backFacingColor =  vec2(0.0, 255.0/255.0);
    
void main()
{
    //gl_FragColor = vec4(mix(backFacingColor, frontFacingColor, float(gl_FrontFacing)),0.0,1.0);
	gl_FragColor = vec4(0.0);
}