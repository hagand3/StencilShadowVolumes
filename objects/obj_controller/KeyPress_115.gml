/// @description Toggle Camera Type

camera_type += 1;
if(camera_type >= camera_types.length)
{
	camera_type = 0;	
}

//re-initialize camera variables
switch(camera_type)
{
	case camera_types.orbit:
	{
		window_set_cursor(cr_default); //unhide cursor
		zfrom = 80; //reset zfrom position
		zfrom_target = 80;
		look_dir = 135;
		look_dir_target = 135;
		rad = 100; //reset radius
		rad_target = 100;
		
		break;
	}
	
	case camera_types.POV:
	{
		window_set_cursor(cr_none); //hide cursor
		look_enabled = true;
		//spawn in corner
		cam_x = 0.2*TILES_X*BLOCK_SIZE;
		cam_y = 0.2*TILES_X*BLOCK_SIZE;
		
		look_dir = 135;
		look_dir_target = 135;
		look_pitch = 0;
		look_pitch_target = 0;
		cam_z = 0;
	
		break;
	}	
}