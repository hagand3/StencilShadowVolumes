z = -64;

spd = 0.0; //0.2
spd_x = random_range(-1,1);
spd_y = random_range(-1,1);
dir = point_direction(0,0,spd_x,spd_y);
spd_x = lengthdir_x(spd,dir);
spd_y = lengthdir_y(spd,dir);
collision_this_frame = false;

rotation_x = 0;
rotation_y = 0;
rotation_z = 0;
rotation_x_phase = 1.0*random(360);
rotation_y_phase = 1.0*random(360);
rotation_z_phase = 1.0*random(360);
rotation_x_spd = 1.0*random_range(-4.0,4.0);
rotation_y_spd = 1.0*random_range(-4.0,4.0);

scale = BLOCK_SIZE;


//model = load_obj("cube.obj", "cube.mtl");
model = 0;
shadow_vbuff = 0;
materialArray = 0;

matrix = -1;
matrix_rot = -1;

drawSelf = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(model, pr_trianglelist, sprite_get_texture(spr_stone, 0));
	//vertex_submit(model, pr_trianglelist, -1);
	matrix_set(matrix_world, matrix_build_identity());
}

drawSelfShadow = function()
{
	//var _matrix = matrix_build(x + BLOCK_SIZE/2, y + BLOCK_SIZE/2, z + BLOCK_SIZE/2, rotation_x, rotation_y, rotation_z, scale*0.99, scale*0.99, scale*0.99);
	matrix_set(matrix_world, matrix);
	//shader_set_uniform_matrix_array(u_Matrix, matrix_rot);
	vertex_submit(shadow_vbuff, pr_trianglelist, -1);
	matrix_set(matrix_world, matrix_build_identity());
}