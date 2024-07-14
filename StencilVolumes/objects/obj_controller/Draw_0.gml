camera = camera_get_active();

//Apply regular camera settings
camera_set_view_mat(camera, cam_view_matrix);
camera_set_proj_mat(camera, cam_proj_matrix);
camera_apply(camera);

//Switch between main rendering pipeline and debug rendering
switch(debug_render)
{
	default: //Main Rendering Pipeline
	{	
		render_ambient_pass(); //Render geometry with ambient light only
		for(var _ii = 0, _light; _ii < NUM_LIGHTS; _ii++) //For each light source:
		{
			_light = lights[_ii]; //Get light source
			render_shadow_volumes(_light); //Render shadow volumes to stencil buffer
			render_lighting_pass(_light); //Render shading and lighting according to stencil buffer
		}
		break;
	}
	
	case debug_renders.normals: //Visualize Normals
	{
		
		draw_clear_depth(1);
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		draw_clear_alpha(c_purple,1.0);
		shader_set(shd_visualize_normals);
		gpu_set_cullmode(cull_counterclockwise);
		with (obj_block){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		shader_reset();
		break;
	}
	
	case debug_renders.shadow_volumes: //renders shadow volumes 
	{
		//Visualize Shadow Volumes
		draw_clear_depth(1);
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_blendmode(bm_normal);
		draw_clear_alpha(c_purple,1.0);
		//render scene
		gpu_set_cullmode(cull_counterclockwise);
		with (obj_block){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		
		//render shadow volumes
		//For each light source:
		for(var _ii = 0, _light; _ii < NUM_LIGHTS; _ii++)
		{
			_light = lights[_ii]; //get light source
			shader_set(shd_visualize_shadow_volumes);
				var _uniform = shader_get_uniform(shd_visualize_shadow_volumes, "LightPos");
				shader_set_uniform_f_array(_uniform, [_light.x,_light.y,_light.z]);
				gpu_set_cullmode(cull_noculling);
				with(obj_block){drawSelfShadow();}
				matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
			shader_reset();
			gpu_set_cullmode(cull_counterclockwise);
		}
		break;
	}
}


