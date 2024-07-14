/// @description GUI

if(show_GUI)
{
	var _w = window_get_width();
	var _h = window_get_height();

	var _w_delta = 0.25*_w;
	var _w1 = 0.03*_w;
	var _w2 = _w1 + _w_delta;
	var _w3 = _w2 + _w_delta;
	var _w4 = _w3 + _w_delta;
	var _h_delta = 0.02*_h;
	var _h1 = 0.86*_h;
	var _h2 = _h1 + _h_delta;
	var _h3 = _h2 + _h_delta;
	var _h4 = _h3 + _h_delta;
	var _h5 = _h4 + _h_delta;
	var _h6 = _h5 + _h_delta;

	draw_set_alpha(0.5);
	draw_rectangle_color(0,_h1,_w,_h,c_black,c_black,c_black,c_black,false);

	draw_set_alpha(1.0);
	draw_set_color(c_white);

	draw_text(_w1,_h2,"F2: Toggle Debug Display");
	draw_text(_w2,_h2,"F3: Toggle Shadow Volume Technique");
	draw_text(_w3,_h2,"F4: Toggle Camera Type");
	draw_text(_w4,_h2,"F11: Show/Hide GUI");
	draw_text(_w4,_h3,"R: Restart Room");
	draw_text(_w4,_h4,"Esc: Exit");

	draw_set_color(c_aqua);
	switch(debug_render)
	{
		default:
		{
			draw_text(_w1,_h3,"Shadow Volumes Demo");
			break;	
		}
	
		case debug_renders.normals:
		{
			draw_text(_w1,_h3,"Geometry Normals");
			break;
		}
	
		case debug_renders.shadow_volumes:
		{
			draw_text(_w1,_h3,"Debug Shadow Volumes Geometry");
			break;
		}
	}

	switch(shadow_volumes_render_technique)
	{
		case shadow_volumes_render_techniques.depth_pass:
		{
			draw_text(_w2,_h3,"Depth Pass / Z-Pass");
			break;
		}
		case shadow_volumes_render_techniques.depth_fail:
		{
			draw_text(_w2,_h3,"Depth Fail / Z-Fail");
			break;
		}
	}

	switch(camera_type)
	{
		case camera_types.orbit:
		{
			draw_text(_w3,_h3,"Orbit");
			draw_text(_w3,_h4,"WASD: pan camera");
			draw_text(_w3,_h5,"Mouse scroll: zoom in/out");

			break;
		}
		case camera_types.POV:
		{
			draw_text(_w3,_h3,"POV");
			draw_text(_w3,_h4,"WASD: move camera x/y");
			draw_text(_w3,_h5,"Mouse: look");
			draw_text(_w3,_h6,"Tab: Look-enable/disable");
			break;
		}
	}

	draw_set_color(c_white);
}
