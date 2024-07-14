//freeze vertex buffers
vertex_freeze(vbuff_skybox);
vertex_freeze(block);
vertex_freeze(zpass_shadow_volume_vertex_buffer);
vertex_freeze(zfail_shadow_volume_vertex_buffer);


//Create blocks
repeat(NUM_BLOCKS)
{
	var _block = instance_create_depth(random(BLOCK_SIZE*TILES_X), random(BLOCK_SIZE*TILES_Y), 0, obj_block);
	_block.model = block;
	_block.shadow_vbuff = zfail_shadow_volume_vertex_buffer; //default zfail
	_block.z = random_range(BLOCK_MIN_Z,BLOCK_MAX_Z);
}

//Show debug overlay if enabled
if(DEBUG_OVERLAY)
{
	call_later(20,time_source_units_frames,function()
	{
		show_debug_overlay(true,true,1);
	});
}

//Create lights at random positions and with random colors
lights = []; //clear lights array
var _ii = 0;
repeat(NUM_LIGHTS)
{
	lights[_ii] = new light(random(TILES_X*BLOCK_SIZE),random(TILES_Y*BLOCK_SIZE),random(TILES_Z*BLOCK_SIZE/2), LIGHT_RADIUS_DEFAULT, make_color_hsv(_ii*(255/NUM_LIGHTS),255,255));
	lights[_ii].idx = _ii; //store index
	_ii++;
}