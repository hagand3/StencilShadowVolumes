var _time = global.time;

//wrap x position if block exits boundary
var _boundary_x = BLOCK_SIZE*TILES_X;
if(x < 0 and spd_x < 0)
{
	x = _boundary_x;	
}	else
if(x > _boundary_x and spd_x > 0)
{
	x = 0;
}
//wrap y position if block exits boundary
var _boundary_y = BLOCK_SIZE*TILES_Y;
if(y < 0 and spd_y < 0)
{
	y = _boundary_y;	
}	else
if(y >=_boundary_y and spd_y > 0)
{
	y = 0;	
}

//move the block
x += spd_x;
y += spd_y;

//rotate the block
rotation_x = (rotation_x_spd*_time + rotation_x_phase) mod 359;
rotation_y = (rotation_y_spd*_time + rotation_y_phase) mod 359;

//build world matrix for drawing
matrix = matrix_build(x, y, z, rotation_x, rotation_y, rotation_z, scale, scale, scale);