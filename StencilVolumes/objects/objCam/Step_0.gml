//advance time
global.time += 0.25;

//Set camera

//Lerp variables for smooth camera
rad = rad != rad_target ? lerp(rad,rad_target,0.05) : rad;
zfrom = zfrom != zfrom_target ? lerp(zfrom,zfrom_target,0.05) : zfrom;	
phase = phase != phase_target ? lerp(phase,phase_target,0.05) : phase;	
look_dir = look_dir != look_dir_target ? lerp(look_dir,look_dir_target,LOOK_SENSITIVITY) : look_dir;
look_pitch = look_pitch != look_pitch_target ? lerp(look_pitch,look_pitch_target,LOOK_SENSITIVITY) : look_pitch;

switch(camera_type)
{
	case camera_types.orbit:
	{
		//radius
		if(mouse_wheel_up())
		{
			rad_target -= 5;
		}
		if(mouse_wheel_down())
		{
			rad_target += 5;
		}
		//pan
		if(keyboard_check(ord("A")))
		{
			phase_target -= 1;	
		}
		if(keyboard_check(ord("D")))
		{
			phase_target += 1;	
		}
		//zfrom
		if(keyboard_check(ord("S")))
		{
			zfrom_target -= 1;	
		}
		if(keyboard_check(ord("W")))
		{
			zfrom_target += 1;	
		}
		
		xfrom = (TILES_X/2)*BLOCK_SIZE + rad*dsin(phase);
		yfrom = (TILES_Y/2)*BLOCK_SIZE + rad*dcos(phase);
		//look towards center
		xto = BLOCK_SIZE*(TILES_X/2);
		yto = BLOCK_SIZE*(TILES_Y/2);
		zto = BLOCK_SIZE/2;
		break;
	}
	
	case camera_types.POV:
	{
		if(mouse_check_button_pressed(mb_left))
		{
			if(look_enabled)
			{
				look_enabled = false;
				window_set_cursor(cr_default);
			}	else
			{
				look_enabled = true;
				window_set_cursor(cr_none);
			}
		}

		if(look_enabled)
		{
			//Mouse Look
			look_dir_target -= (window_mouse_get_x() - window_get_width() / 2) / 20;
		    look_pitch_target -= (window_mouse_get_y() - window_get_height() / 2) / 20;
		    look_pitch_target = clamp(look_pitch_target, -85, 85);
			window_mouse_set(window_get_width() / 2, window_get_height() / 2);
		}
		
		//Movement
		var move_speed = 1;
	    var dx = 0;
	    var dy = 0;

	    if (keyboard_check(ord("A"))) {
	        dx += dsin(look_dir) * move_speed;
	        dy += dcos(look_dir) * move_speed;
	    }

	    if (keyboard_check(ord("D"))) {
	        dx -= dsin(look_dir) * move_speed;
	        dy -= dcos(look_dir) * move_speed;
	    }

	    if (keyboard_check(ord("W"))) {
	        dx -= dcos(look_dir) * move_speed;
	        dy += dsin(look_dir) * move_speed;
	    }

	    if (keyboard_check(ord("S"))) {
	        dx += dcos(look_dir) * move_speed;
	        dy -= dsin(look_dir) * move_speed;
	    }
		
		//adjust camera position position
	    cam_x += dx;
	    cam_y += dy;
		
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
cameraMat = matrix_build_lookat(xfrom, yfrom, zfrom, xto, yto, zto, 0, 0, 1);
cameraProjMat = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 32000);
cameraProjMatBias = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 30000); //biased projection matrix (to remedy z-fighting with z-fail shadow volume geometry with model geometry)


if keyboard_check(ord("J")){
	lightArray[0] -= 0.1;	
}
if keyboard_check(ord("K")){
	lightArray[0] += 0.1;	
}
if keyboard_check(ord("U")){
	lightArray[1] -= 0.1;	
}
if keyboard_check(ord("I")){
	lightArray[1] += 0.1;	
}
if keyboard_check(ord("N")){
	lightArray[2] -= 0.1;	
}
if keyboard_check(ord("M")){
	lightArray[2] += 0.1;	
}

