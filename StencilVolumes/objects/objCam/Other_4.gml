//Create cubes
repeat(NUM_CUBES)
{
	var _cube = instance_create_depth(random(BLOCK_SIZE*TILES_X), random(BLOCK_SIZE*TILES_Y), 0, objCube);
	_cube.model = block;
	_cube.shadow_vbuff = shadowVBuffer;
	_cube.z = random_range(BLOCK_MIN_Z,BLOCK_MAX_Z);
}

if(DEBUG_OVERLAY)
{
	call_later(60,time_source_units_frames,function()
	{
		show_debug_overlay(true,false,1);
	});
}