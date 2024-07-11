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
		zfrom = 80; //reset zfrom position
		rad = 100; //reset radius
		break;
	}
	
	case camera_types.POV:
	{
		rad = 100;
		
		xfrom = cam_x;
		yfrom = cam_y;
		zfrom = cam_z + CAM_POV_Z_OFFSET;
		xto = xfrom - rad * dcos(look_dir) * dcos(look_pitch);
		yto = yfrom + rad * dsin(look_dir) * dcos(look_pitch);
		zto = zfrom + rad * dsin(look_pitch);
		break;
	}	
}