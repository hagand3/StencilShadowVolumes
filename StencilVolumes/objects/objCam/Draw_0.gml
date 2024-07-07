var camera = camera_get_active();
	
draw_clear_alpha(c_purple,1.0);
camera_set_view_mat(camera, cameraMat);
camera_set_proj_mat(camera, cameraProjMat);
camera_apply(camera);

gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_cullmode(cull_counterclockwise);
gpu_set_stencil_enable(false);
gpu_set_colorwriteenable(false,false,false,false);
	
	//Render geometry to depth buffer for shadow volumes to depth-test
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube){drawSelf();}
	
//Stencil buffer setup  (depth-pass)
gpu_set_zwriteenable(false);
gpu_set_colorwriteenable(false,false,false,false);
gpu_set_stencil_enable(true);
draw_clear_stencil(0); //clear stencil buffer
gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed
gpu_set_stencil_ref(0); //set reference to 0 (shouldn't matter here as the stencil function always passes if depth test passes)


	//Render shadow volumes to stencil buffer
	shader_set(sh_render_shadow_volumes);
	for(var _ii = 0; _ii < num_lights; _ii++)
	{
		var _uniform = shader_get_uniform(sh_render_shadow_volumes, "LightPos");
		//shader_set_uniform_f_array(_uniform, light_pos[_ii]);
		//shader_set_uniform_f_array(_uniform, lightArray);
		//shader_set_uniform_f_array(_uniform, [100*lightArray[0],100*lightArray[1],10*lightArray[2]]);
		shader_set_uniform_f_array(_uniform, [400,400,-60]);
			
			//render front-facing shadow volume polygons
			gpu_set_cullmode(cull_counterclockwise);
			gpu_set_stencil_pass(stencilop_incr); //increment
			//gpu_set_colorwriteenable(true,false,false,true);
			with(objCube){drawSelfShadow();}
		
			//render rear-facing shadow volume polygons
			gpu_set_cullmode(cull_clockwise);
			gpu_set_stencil_pass(stencilop_decr); //decrement
			//gpu_set_colorwriteenable(false,false,true,true);
			with(objCube){drawSelfShadow();}
	}
	shader_reset();
	
	
draw_clear_depth(1);
gpu_set_colorwriteenable(true,true,true,true);
gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_stencil_pass(stencilop_keep); //increment
gpu_set_stencil_ref(0);
	
	//Render unshaded geometry
	gpu_set_cullmode(cull_noculling);
	gpu_set_stencil_func(cmpfunc_equal);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube)
	{
		drawSelf();	
	}
	
	//Render shaded geometry
	//gpu_set_cullmode(cull_noculling);
	gpu_set_stencil_func(cmpfunc_notequal);
	shader_set(shd_render_shaded);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube)
	{
		drawSelf();	
	}
	shader_reset();

//reset for drawing main surface
gpu_set_stencil_enable(false);
gpu_set_stencil_func(cmpfunc_always);


////Visualize Normals
//draw_clear_depth(1);
//gpu_set_zwriteenable(true);
//gpu_set_ztestenable(true);
//draw_clear_alpha(c_purple,1.0);
//shader_set(shd_test);
//vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
//with (objCube)
//{
//	drawSelf();	
//}
//shader_reset();


