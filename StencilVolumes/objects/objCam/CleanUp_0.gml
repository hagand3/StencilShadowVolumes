///// @description Insert description here
//// You can write your code in this editor


//draw_clear_alpha(c_teal,0.0); //clear surface (color doesn't matter)
//camera_set_view_mat(camera, cameraMat); //set view matrix
//camera_set_proj_mat(camera, cameraProjMat); //set projection matrix
//camera_apply(camera); //apply camera settings
	
////Render geometry as shaded
//renderGeometry(); //apply blendmodes or shaders here to render "shaded" texture, as if there is no light source
	
////Stencil buffer setup
//gpu_set_colorwriteenable(false,false,false,false); //disable color/alpha writing to surface
//gpu_set_zwriteenable(false); //disable writing to depth buffer
//gpu_set_stencil_enable(true); //enable stencil buffer
//draw_clear_stencil(0); //clear stencil buffer to 0 (to make full use of 8-bits incase there are lots of volumes)
//gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed (reference value doesn't matter here)
	
////shader to render shadow volumes. Main goal of the shader is to extrude "extrudable" vertices away from light source along light direction vector towards infinity. 
////Can get away with triangles instead of quads if extrude distance is large enough (approximates a quad)
//shader_set(sh_render_shadow_volumes); 
//	var _uniform = shader_get_uniform(sh_shadow, "LightDirec");
//	shader_set_uniform_f_array(_uniform, lightArray); //light direction vector
			
//	//render front-facing shadow volume polygons
//	gpu_set_cullmode(cull_counterclockwise);
//	gpu_set_stencil_pass(stencilop_incr); //increment stencil buffer if depth-test passes
//	vertex_submit(shadowVBuffer, pr_trianglelist, -1); //render shadow volumes with only front-facing polygons
			
//	//render rear-facing shadow volume polygons
//	gpu_set_cullmode(cull_clockwise);
//	gpu_set_stencil_pass(stencilop_decr); //decrement stencil buffer if depth-test passes
//	vertex_submit(shadowVBuffer, pr_trianglelist, -1); //render shadow volumes with only back-facing polygons
			
//shader_reset();
	
////Final geometry pass
//gpu_set_colorwriteenable(true,true,true,true); //re-enable color/alpha writing
//gpu_set_zwriteenable(true); //re-enable depth buffer writing
//gpu_set_cullmode(cull_counterclockwise); //reset cullmode
//gpu_set_stencil_ref(0); //set 0 reference (equal increments and decrements, i.e. entered and left shadow volume, or no shadow volume at all)
//gpu_set_stencil_func(cmpfunc_equal); //set stencil to look for 0 ref 
	
////Render geometry unshaded
//renderGeometry(); 
	
//gpu_set_stencil_enable(false); //disable stencil buffer when done