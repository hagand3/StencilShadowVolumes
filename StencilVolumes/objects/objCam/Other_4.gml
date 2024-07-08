//Create cubes
repeat(NUM_CUBES)
{
	var _ii = random_range(-5,5);
	var _jj = random_range(-5,5);
	var _z = random_range(BLOCK_MIN_Z,BLOCK_MAX_Z);
	var _cube = instance_create_depth(BLOCK_SIZE*(50-_ii), BLOCK_SIZE*(50-_jj), 0, objCube);
	//_cube.model = model;
	//_cube.scale = BLOCK_SIZE;
	_cube.model = block;
	_cube.scale = 1;
	_cube.shadow_vbuff = shadowVBuffer;
	_cube.z = _z;
}