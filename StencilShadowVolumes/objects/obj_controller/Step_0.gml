//advance time
global.time += 0.25;

//Lerp variables for smooth camera
rad = rad != rad_target ? lerp(rad,rad_target,0.05) : rad;
zfrom = zfrom != zfrom_target ? lerp(zfrom,zfrom_target,0.05) : zfrom;	
look_dir = look_dir != look_dir_target ? lerp(look_dir,look_dir_target,LOOK_SENSITIVITY) : look_dir;
look_pitch = look_pitch != look_pitch_target ? lerp(look_pitch,look_pitch_target,LOOK_SENSITIVITY) : look_pitch;

//Set Camera
switch(camera_type)
{
	//Orbit camera
	case camera_types.orbit:
	{
		//radius
		if(mouse_wheel_up()){rad_target -= 5;}
		if(mouse_wheel_down()){rad_target += 5;}
		//pan
		if(keyboard_check(ord("A"))){look_dir_target -= 1;}
		if(keyboard_check(ord("D"))){look_dir_target += 1;}
		//height
		if(keyboard_check(ord("S"))){zfrom_target -= 1;}
		if(keyboard_check(ord("W"))){zfrom_target += 1;}
		//calculate xfrom/yfrom
		xfrom = (TILES_X/2)*BLOCK_SIZE + rad*dsin(look_dir);
		yfrom = (TILES_Y/2)*BLOCK_SIZE + rad*dcos(look_dir);
		//look towards center
		xto = BLOCK_SIZE*(TILES_X/2);
		yto = BLOCK_SIZE*(TILES_Y/2);
		zto = BLOCK_SIZE/2;
		break;
	}
	
	//First-person POV camera
	case camera_types.POV:
	{
		//only recalculate mouse look if enabled
		if(look_enabled)
		{
			//Mouse Look
			look_dir_target -= (window_mouse_get_x() - window_get_width() / 2) / 20;
		    look_pitch_target -= (window_mouse_get_y() - window_get_height() / 2) / 20;
		    look_pitch_target = clamp(look_pitch_target, -85, 85);
			window_mouse_set(window_get_width() / 2, window_get_height() / 2);
		}
		
		//Movement
		var _move_speed = CAM_POV_MOVE_SPEED;
	    var _dx = 0;
	    var _dy = 0;

		//look direction
	    if (keyboard_check(ord("A"))) 
		{
	        _dx += dsin(look_dir) * _move_speed;
	        _dy += dcos(look_dir) * _move_speed;
	    }

	    if (keyboard_check(ord("D"))) 
		{
	        _dx -= dsin(look_dir) * _move_speed;
	        _dy -= dcos(look_dir) * _move_speed;
	    }

	    if (keyboard_check(ord("W"))) 
		{
	        _dx -= dcos(look_dir) * _move_speed;
	        _dy += dsin(look_dir) * _move_speed;
	    }

	    if (keyboard_check(ord("S"))) 
		{
	        _dx += dcos(look_dir) * _move_speed;
	        _dy -= dsin(look_dir) * _move_speed;
	    }
		
		//adjust camera position position
	    cam_x += _dx;
	    cam_y += _dy;
		
		xfrom = cam_x;
		yfrom = cam_y;
		zfrom = cam_z + CAM_POV_Z_OFFSET;
		xto = xfrom - dcos(look_dir) * dcos(look_pitch);
		yto = yfrom + dsin(look_dir) * dcos(look_pitch);
		zto = zfrom + dsin(look_pitch);
		break;
	}
}

//Calculate camera matrices
cam_view_matrix = matrix_build_lookat(xfrom, yfrom, zfrom, xto, yto, zto, 0, 0, 1);
cam_proj_matrix = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 32000);
cam_proj_bias_matrix = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 30000); //biased projection matrix (to remedy z-fighting with z-fail shadow volume geometry with model geometry)

