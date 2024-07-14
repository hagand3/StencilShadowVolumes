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
		visualize_normals();
		break;
	}
	
	case debug_renders.shadow_volumes: //Visualize partially extruded Shadow Volumes 
	{
		visualize_shadow_volumes();
		break;
	}
}


