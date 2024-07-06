var _time = global.time;

collision_this_frame = false; //reset collision flag

//invisible box
var _r = BLOCK_SIZE*15;
var _d = BLOCK_SIZE*15;

//wrap position
if(x < _d-_r and spd_x < 0)
{
	x = _d + _r;	
}
if(x > _d+_r and spd_x > 0)
{
	x = _d - _r;
}
if(y < _d-_r and spd_y < 0)
{
	y = _d + _r;	
}
if(y >= _d+_r and spd_y > 0)
{
	y = _d - _r;	
}

//if((x < _d-_r and spd_x < 0) or (x >= _d+_r and spd_x > 0))
//{
//	spd_x *= -1; //flip direction
//}

//if((y < _d-_r and spd_y < 0) or (y >= _d+_r and spd_y > 0))
//{
//	spd_y *= -1; //flip direction
//}

x += spd_x;
y += spd_y;

rotation_x = rotation_x_spd*_time + rotation_x_phase;
rotation_y = rotation_y_spd*_time + rotation_y_phase;
//rotation_z = 10.2*_time;

matrix = matrix_build(x + BLOCK_SIZE/2, y + BLOCK_SIZE/2, -z-BLOCK_SIZE/2, rotation_x, rotation_y, rotation_z, BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE);
