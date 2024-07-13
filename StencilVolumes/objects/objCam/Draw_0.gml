camera = camera_get_active();

//Apply regular camera settings
camera_set_view_mat(camera, cam_view_matrix);
camera_set_proj_mat(camera, cam_proj_matrix);
camera_apply(camera);

//Main Rendering Pipeline

render_ambient_pass(); //render geometry with ambient light only

//For each light source:
for(var _ii = 0, _light; _ii < NUM_LIGHTS; _ii++)
{
	_light = lights[_ii]; //get light source
	render_shadow_volumes(_light); //render shadow volumes to stencil buffer
	render_lighting_pass(_light); //render shading and lighting according to stencil buffer
}

//If debug render active, draw ontop
switch(debug_render)
{
	case debug_renders.normals:
	{
		//Visualize Normals
		draw_clear_depth(1);
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		draw_clear_alpha(c_purple,1.0);
		shader_set(shd_test);
		gpu_set_cullmode(cull_counterclockwise);
		with (objCube){drawSelf();}
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		shader_reset();
		break;
	}
	
	//renders shadow volumes 
	case debug_renders.shadow_volumes:
	{
		//Visualize Shadow Volumes
		draw_clear_depth(1);
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_blendmode(bm_normal);
		draw_clear_alpha(c_purple,1.0);
		//render scene
		gpu_set_cullmode(cull_counterclockwise);
		with (objCube){drawSelf();}
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
				with(objCube){drawSelfShadow();}
			shader_reset();
			gpu_set_cullmode(cull_counterclockwise);
		}
		break;
	}
	
	default:
	{	
		//do nothing
		break;
	}
}


