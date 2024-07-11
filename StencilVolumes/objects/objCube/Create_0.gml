
z = 0; //z position

//speed and direction
spd = 0.4; //0.2
spd_x = random_range(-1,1);
spd_y = random_range(-1,1);
dir = point_direction(0,0,spd_x,spd_y);
spd_x = lengthdir_x(spd,dir);
spd_y = lengthdir_y(spd,dir);

//rotation
rotation_x = 0;
rotation_y = 0;
rotation_z = 0;

//initial rotation offset
rotation_x_phase = random(360);
rotation_y_phase = random(360);
rotation_z_phase = random(360);

//rotation speeds
rotation_x_spd = random_range(-4.0,4.0);
rotation_y_spd = random_range(-4.0,4.0);

//scale
scale = 1; //model scale 

//world matrix
matrix = -1;

//Cube model and shadow vertex buffer
//model = load_obj("cube.obj", "cube.mtl");
model = 0;
shadow_vbuff = 0;


//Method to draw self with matrix applied (position, rotation, and scale applied)
drawSelf = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(model, pr_trianglelist, sprite_get_texture(spr_stone, 0));
	matrix_set(matrix_world, matrix_build_identity());
}
//Method to draw shadow with matrix applied (position, rotation, and scale applied)
drawSelfShadow = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(shadow_vbuff, pr_trianglelist, -1);
	matrix_set(matrix_world, matrix_build_identity());
}