z = 0; //z position

//speed and direction
spd = 0.2; //speed
spd_x = random_range(-1,1); //speed vector x component
spd_y = random_range(-1,1); //speed vector y component
dir = point_direction(0,0,spd_x,spd_y); //calculate direction
spd_x = lengthdir_x(spd,dir); //normalize x component to spd
spd_y = lengthdir_y(spd,dir); //normalize y component to spd

//rotation
rotation_x = 0;
rotation_y = 0;
rotation_z = 0;

//initial rotation offset
rotation_x_phase = random(360);
rotation_y_phase = random(360);
rotation_z_phase = random(360);

//rotation speeds
rotation_x_spd = random_range(-2.0,2.0);
rotation_y_spd = random_range(-2.0,2.0);

//scale
scale = 1; //model scale 

//world matrix
matrix = -1;

//Vertex buffers
model = 0; //block geometry
shadow_vbuff = 0; //block shadow volume

//Method to draw self with matrix applied (position, rotation, and scale applied)
drawSelf = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(model, pr_trianglelist, sprite_get_texture(spr_stone, 0));
}
//Method to draw shadow with matrix applied (position, rotation, and scale applied)
drawSelfShadow = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(shadow_vbuff, pr_trianglelist, -1);
}