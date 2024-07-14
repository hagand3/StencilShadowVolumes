/// @description Toggle look-enable (POV only)

if(camera_type == camera_types.POV)
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