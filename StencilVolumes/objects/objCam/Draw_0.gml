//draw_clear(c_orange);
var camera = camera_get_active();

if !(surface_exists(shadowSurface)){
	shadowSurface = surface_create(surface_get_width(application_surface), surface_get_height(application_surface));
}
//gpu_set_blendmode(bm_add);
//surface_set_target(shadowSurface);
	draw_clear_alpha(c_teal,0.0);
	camera_set_view_mat(camera, cameraMat);
	camera_set_proj_mat(camera, cameraProjMat);
	camera_apply(camera);
	
	//Render geometry as shaded
	//shader_set(shd_render_shaded);
		vertex_submit(ground, pr_trianglelist, sprite_get_texture(sprRock,0));
		with (objCube){
			event_perform(ev_draw, 0);	
		}
	//shader_reset();
	
	//Stencil buffer setup  (depth-pass)
	gpu_set_colorwriteenable(false,false,false,false);
	gpu_set_zwriteenable(false);
	gpu_set_stencil_enable(true);
	draw_clear_stencil(0); //clear stencil buffer
	gpu_set_stencil_ref(0);
	gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed
	
	
	
	shader_set(sh_render_shadow_volumes);
		var _uniform = shader_get_uniform(sh_shadow, "LightDirec");
		shader_set_uniform_f_array(_uniform, lightArray);
			matrix_set(matrix_world, modelMatrix);
			
			//render front-facing shadow volume polygons
			gpu_set_cullmode(cull_counterclockwise);
			gpu_set_stencil_pass(stencilop_incr); //increment
			
			vertex_submit(shadowVBuffer, pr_trianglelist, -1);
			
			//render rear-facing shadow volume polygons
			gpu_set_cullmode(cull_clockwise);
			gpu_set_stencil_pass(stencilop_decr); //decrement
			vertex_submit(shadowVBuffer, pr_trianglelist, -1);
			
			matrix_set(matrix_world, matrix_build_identity());
	shader_reset();
	
	
	gpu_set_colorwriteenable(true,true,true,true);
	gpu_set_zwriteenable(true);
	gpu_set_cullmode(cull_counterclockwise);
	gpu_set_stencil_ref(0);
	gpu_set_stencil_func(cmpfunc_notequal); //set stencil to look for 0 ref (equal increments and decrements)
	
	
	//Render geometry unshaded
	shader_set(shd_render_shaded);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(sprRock,0));
	with (objCube){
		event_perform(ev_draw, 0);	
	}
	shader_reset();
	
	gpu_set_stencil_enable(false);
	
	/* Fake Stencil Buffer Variant
	gpu_set_cullmode(cull_noculling);
	gpu_set_blendmode(bm_add);
	gpu_set_zwriteenable(false);
	shader_set(sh_shadow);
		var _uniform = shader_get_uniform(sh_shadow, "LightDirec");
		shader_set_uniform_f_array(_uniform, lightArray);
			matrix_set(matrix_world, modelMatrix);
			vertex_submit(shadowVBuffer, pr_trianglelist, -1);
			matrix_set(matrix_world, matrix_build_identity());
	shader_reset();
    
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);
    gpu_set_blendmode(bm_normal);
	*/
	//surface_reset_target();
	
	//vertex_submit(ground, pr_trianglelist, -1);
	//with (objCube){
	//	event_perform(ev_draw, 0);	
	//}

//camera_set_view_mat(camera, cameraMat);
//camera_set_proj_mat(camera, cameraProjMat);
//camera_apply(camera);

////var _uniform = shader_get_uniform(sh_shadow, "LightDirec");
////shader_set_uniform_f_array(_uniform, lightArray);
////shader_set(sh_shadow);

//// Everything must be drawn after the 3D projection has been set
//vertex_submit(ground, pr_trianglelist, sprite_get_texture(sprRock, 0));
//with (objCube){
//	event_perform(ev_draw, 0);	
//}

////shader_reset();