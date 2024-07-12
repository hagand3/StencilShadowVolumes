camera = camera_get_active();

//Apply regular camera settings
camera_set_view_mat(camera, cameraMat);
camera_set_proj_mat(camera, cameraProjMat);
camera_apply(camera);

//Main Rendering Pipeline

render_ambient_pass(); //render geometry with ambient light only

//For each light source:
render_shadow_volumes(); //render shadow volumes to stencil buffer





	


//Re-apply regular camera settings
camera_set_proj_mat(camera, cameraProjMat);
camera_apply(camera);

gpu_set_colorwriteenable(true,true,true,true); //enable color and alpha writing
//gpu_set_zwriteenable(true); //enable depth writing
gpu_set_ztestenable(true); //enable depth testing
gpu_set_cullmode(cull_counterclockwise); //set cull mode to counterclockwise (back-faces)
gpu_set_stencil_ref(STENCIL_REF_VAL);
	
	draw_set_lighting(true); //reactivate lighting (ambient term should still be set to c_black, meaning no additional ambient light is rendered)
	draw_light_define_point(0, lightArray[0], lightArray[1], lightArray[2], 100, c_red); //define point source from light struct
	draw_light_enable(0, true); //enable light source
	
	//Render unshaded geometry
	gpu_set_stencil_func(cmpfunc_equal);
	gpu_set_blendmode(bm_add); //set additive blend mode
	with (objCube){drawSelf();}
	vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
	gpu_set_blendmode(bm_normal);
	
	draw_light_enable(0,false); //disable point source
	draw_set_lighting(false); //disable lighting
	
	//Render shaded geometry
	gpu_set_stencil_func(cmpfunc_notequal);
	//shader_set(shd_render_shaded);
	gpu_set_blendmode(bm_subtract);
	with (objCube){drawSelf();}
	vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
	gpu_set_blendmode(bm_normal);
	//shader_reset();

//reset for drawing main surface
gpu_set_stencil_enable(false); //disable stencil test

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
	
	case debug_renders.shadow_volumes:
	{
		//Visualize Shadow Volumes
		draw_clear_depth(1);
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		draw_clear_alpha(c_purple,1.0);
		//render scene
		gpu_set_cullmode(cull_counterclockwise);
		with (objCube){drawSelf();}
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		
		//render shadow volumes
		//gpu_set_zwriteenable(false);
		//gpu_set_ztestenable(false);
		gpu_set_blendmode(bm_add);
		shader_set(shd_visualize_shadow_volumes);
			var _uniform = shader_get_uniform(shd_visualize_shadow_volumes, "LightPos");
			shader_set_uniform_f_array(_uniform, [lightArray[0],lightArray[1],lightArray[2]]);
			gpu_set_cullmode(cull_noculling);
			with(objCube){drawSelfShadow();}
		shader_reset();
		gpu_set_cullmode(cull_counterclockwise);
		gpu_set_blendmode(bm_normal);
		break;
	}
	
	default:
	{	
		//do nothing
		break;
	}
}


