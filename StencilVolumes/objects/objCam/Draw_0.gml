//draw_clear(c_orange);
var camera = camera_get_active();

if !(surface_exists(shadowSurface)){
	shadowSurface = surface_create(surface_get_width(application_surface), surface_get_height(application_surface));
}
if !(surface_exists(shadowSurface2)){
	shadowSurface2 = surface_create(surface_get_width(application_surface), surface_get_height(application_surface));
}
//gpu_set_blendmode(bm_add);
//surface_set_target(shadowSurface);
	
	camera_set_view_mat(camera, cameraMat);
	camera_set_proj_mat(camera, cameraProjMat);
	camera_apply(camera);
	draw_clear_alpha(c_white,1.0);
	gpu_set_zwriteenable(true);
	gpu_set_ztestenable(true);
	gpu_set_cullmode(cull_counterclockwise);
	gpu_set_zfunc(cmpfunc_lessequal);
	//gpu_set_colorwriteenable(true,true,true,true);
	gpu_set_colorwriteenable(false,false,false,false);
	//Render geometry as shaded
	//shader_set(shd_render_shaded);
		//matrix_set(matrix_world, matrix_build_identity());
		
		vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
		with (objCube)
		{
			//event_perform(ev_draw, 0);	
			drawSelf();
		}
	//shader_reset();
	
	//Stencil buffer setup  (depth-pass)
	gpu_set_zwriteenable(false);
	gpu_set_stencil_enable(true);
	gpu_set_colorwriteenable(false,false,false,false);
	draw_clear_stencil(0); //clear stencil buffer
	gpu_set_stencil_ref(0);
	gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed
	
	
	shader_set(sh_render_shadow_volumes);
		var _uniform = shader_get_uniform(sh_shadow, "LightDirec");
		shader_set_uniform_f_array(_uniform, lightArray);
			
			//render front-facing shadow volume polygons
			gpu_set_cullmode(cull_counterclockwise);
			gpu_set_stencil_pass(stencilop_incr); //increment
			with(objCube)
			{
				drawSelfShadow();	
			}
		
			//render rear-facing shadow volume polygons
			gpu_set_cullmode(cull_clockwise);
			gpu_set_stencil_pass(stencilop_decr); //decrement
			with(objCube)
			{
				drawSelfShadow();
			}

	shader_reset();
	
	
	draw_clear_depth(1);
	gpu_set_colorwriteenable(true,true,true,true);
	gpu_set_zwriteenable(true);
	gpu_set_zfunc(cmpfunc_lessequal);
	gpu_set_ztestenable(true);
	gpu_set_cullmode(cull_counterclockwise);
	gpu_set_stencil_pass(stencilop_keep); //increment
	gpu_set_stencil_ref(0);
	
	
	//draw_set_color(c_red);
	//draw_rectangle(0,0,surface_get_width(application_surface),surface_get_height(application_surface),false);
	
	//draw_clear_depth(1);
	
	//draw_set_color(c_green);
	//draw_rectangle(0,0,surface_get_width(application_surface),surface_get_height(application_surface),false);
	//gpu_set_stencil_func(cmpfunc_notequal);
	
	
	//Render geometry shaded
	
	
	gpu_set_stencil_func(cmpfunc_equal);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube)
	{
		drawSelf();	
	}
	
	gpu_set_stencil_func(cmpfunc_notequal);
	shader_set(shd_render_shaded);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube)
	{
		drawSelf();	
	}
	shader_reset();
		
	gpu_set_stencil_enable(false);
