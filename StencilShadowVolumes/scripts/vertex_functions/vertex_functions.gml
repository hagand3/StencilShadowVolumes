/// @param vbuffer
/// @param xx
/// @param yy
/// @param zz
/// @param nx
/// @param ny
/// @param nz
/// @param utex
/// @param vtex
/// @param color
/// @param alpha
function vertex_add_point(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10) {

	var vbuffer = argument0;
	var xx = argument1;
	var yy = argument2;
	var zz = argument3;
	var nx = argument4;
	var ny = argument5;
	var nz = argument6;
	var utex = argument7;
	var vtex = argument8;
	var color = argument9;
	var alpha = argument10;

	// Collapse four function calls into a single one
	vertex_position_3d(vbuffer, xx, yy, zz);
	vertex_normal(vbuffer, nx, ny, nz);
	vertex_color(vbuffer, color, alpha);
	vertex_texcoord(vbuffer, utex, vtex);

}