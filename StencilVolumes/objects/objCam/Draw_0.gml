var camera = camera_get_active();

var _stencil_ref_val = 127; //stencil reference value

//Apply camera settings
camera_set_view_mat(camera, cameraMat);
camera_set_proj_mat(camera, cameraProjMat);
camera_apply(camera);

draw_clear_alpha(c_purple,0.0); //clear surface color and alpha
gpu_set_zwriteenable(true); //enable depth buffer writing
gpu_set_ztestenable(true); //enable depth testing
gpu_set_zfunc(cmpfunc_lessequal); //default depth testing
gpu_set_cullmode(cull_counterclockwise); //cull counterclockwise geometry (back-faces in this case)
gpu_set_colorwriteenable(true,true,true,true); //enable color and alpha writing
	
	//Render geometry to depth buffer for shadow volumes to depth-test
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube){drawSelf();}
	
//Shadow Volume Rendering
gpu_set_zwriteenable(false); //disable depth writing but keep depth testing enabled
gpu_set_colorwriteenable(false,false,false,false); //disable color and alpha writing
//Stencil buffer setup
gpu_set_stencil_enable(true); //enable stencil buffer
gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed
gpu_set_stencil_pass(stencilop_keep); //keep (default)
gpu_set_stencil_fail(stencilop_keep); //keep (default)
gpu_set_stencil_depth_fail(stencilop_keep); //keep (default)
draw_clear_stencil(_stencil_ref_val); //clear stencil buffer to reference value
gpu_set_stencil_ref(_stencil_ref_val); //set stencil reference value

//Render shadow volumes using either depth-pass or depth-fail technique
switch(shadow_volumes_render_technique)
{
	//Depth Pass:
	case shadow_volumes_render_techniques.depth_pass:
	{
		shader_set(sh_render_shadow_volumes);
		for(var _ii = 0; _ii < num_lights; _ii++)
		{
			var _uniform = shader_get_uniform(sh_render_shadow_volumes, "LightPos");
			//shader_set_uniform_f_array(_uniform, light_pos[_ii]);
			//shader_set_uniform_f_array(_uniform, lightArray);
			//shader_set_uniform_f_array(_uniform, [100*lightArray[0],100*lightArray[1],10*lightArray[2]]);
			shader_set_uniform_f_array(_uniform, [10*lightArray[0],10*lightArray[1],10*lightArray[2]]);
			
				//render front-facing shadow volume polygons
				gpu_set_cullmode(cull_counterclockwise);
				gpu_set_stencil_pass(stencilop_incr_wrap); //increment
				//gpu_set_colorwriteenable(true,false,false,true);
				with(objCube){drawSelfShadow();}
		
				//render rear-facing shadow volume polygons
				gpu_set_cullmode(cull_clockwise);
				gpu_set_stencil_pass(stencilop_decr_wrap); //decrement
				//gpu_set_colorwriteenable(false,false,true,true);
				with(objCube){drawSelfShadow();}
		}
		shader_reset();
		gpu_set_stencil_pass(stencilop_keep); //reset to default (keep)
		break;
	}
	
	//Depth Fail:
	case shadow_volumes_render_techniques.depth_fail:
	{
		shader_set(sh_render_shadow_volumes);
		for(var _ii = 0; _ii < num_lights; _ii++)
		{
			var _uniform = shader_get_uniform(sh_render_shadow_volumes, "LightPos");
			//shader_set_uniform_f_array(_uniform, light_pos[_ii]);
			//shader_set_uniform_f_array(_uniform, lightArray);
			//shader_set_uniform_f_array(_uniform, [100*lightArray[0],100*lightArray[1],10*lightArray[2]]);
			shader_set_uniform_f_array(_uniform, [10*lightArray[0],10*lightArray[1],10*lightArray[2]]);
			
				//render front-facing shadow volume polygons
				gpu_set_cullmode(cull_clockwise);
				gpu_set_stencil_depth_fail(stencilop_incr_wrap); //increment
				with(objCube){drawSelfShadow();}
			
				//render rear-facing shadow volume polygons
				gpu_set_cullmode(cull_counterclockwise);
				gpu_set_stencil_depth_fail(stencilop_decr_wrap); //decrement
				with(objCube){drawSelfShadow();}
		}
		shader_reset();
		gpu_set_stencil_depth_fail(stencilop_keep); //reset to default (keep)
		break;
	}
}



//draw_clear_depth(1); //clear depth buffer to zfar value
gpu_set_colorwriteenable(true,true,true,true); //enable color and alpha writing
gpu_set_zwriteenable(true); //enable depth writing
gpu_set_ztestenable(true); //enable depth testing
gpu_set_cullmode(cull_counterclockwise); //set cull mode to counterclockwise (back-faces)
//gpu_set_stencil_pass(stencilop_keep); //keep
//gpu_set_stencil_fail(stencilop_keep); //keep
//gpu_set_stencil_depth_fail(stencilop_keep); //keep
gpu_set_stencil_ref(_stencil_ref_val);
	
	////Render unshaded geometry
	//gpu_set_stencil_func(cmpfunc_equal);
	//vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	//with (objCube)
	//{
	//	drawSelf();	
	//}
	
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
gpu_set_stencil_enable(false); //disable stencil test


if(view_normals)
{
	//Visualize Normals
	draw_clear_depth(1);
	gpu_set_zwriteenable(true);
	gpu_set_ztestenable(true);
	draw_clear_alpha(c_purple,1.0);
	shader_set(shd_test);
	gpu_set_cullmode(cull_counterclockwise);
	vertex_submit(ground, pr_trianglelist, sprite_get_texture(spr_grass,0));
	with (objCube)
	{
		drawSelf();	
	}
	shader_reset();
}

