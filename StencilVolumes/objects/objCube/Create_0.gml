z = -64;

rotation_x = 0;
rotation_y = 0;
rotation_z = 0;

//model = load_obj("cube.obj", "cube.mtl");
model = 0;
shadow_vbuff = 0;
materialArray = 0;

matrix = matrix_build(x + BLOCK_SIZE/2, y + BLOCK_SIZE/2, -BLOCK_SIZE/2, 0, 0, 0, BLOCK_SIZE/2, BLOCK_SIZE/2, BLOCK_SIZE/2);

drawSelf = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(model, pr_trianglelist, sprite_get_texture(sprRock, 0));
	//vertex_submit(model, pr_trianglelist, -1);
	matrix_set(matrix_world, matrix_build_identity());
}

drawSelfShadow = function()
{
	matrix_set(matrix_world, matrix);
	vertex_submit(shadow_vbuff, pr_trianglelist, -1);
	matrix_set(matrix_world, matrix_build_identity());
}