
//BUGS:
	//camera drifts up slowly in POV camera mode.

//TODO:
	//Create separate shadow volumes buffer for z-pass
	//Add debug view inspector for lighting
	
//Optimizations:
	//Extend shadow volumes only as far as light radius
	
//Model requirements:
	//composed of triangles (duh)
	//closed (2-manifold) geometry
	//consistent winding direction
	
//Experimental:
	//Soft shadows through clustered light sources
	//Soft shadows through shadow volume jittering

//Init 
global.time = 0;

gpu_set_ztestenable(true); //enable depth testing
gpu_set_zwriteenable(true); //enable depth writing 
gpu_set_alphatestenable(true); //enable alpha testing
gpu_set_alphatestref(0.5); //set alpha testing reference

#region Macros (change these as you see fit)

	#macro NUM_BLOCKS 100
	#macro NUM_LIGHTS 7 //max 7
	#macro BLOCK_MIN_Z 30 //min z spawn position for blocks
	#macro BLOCK_MAX_Z 80 //max z spawn position for blocks
	#macro TILES_X 40 //Area x dimension
	#macro TILES_Y 40 //Area y dimension
	#macro TILES_Z 40 //Area z dimension
	//Lights
	#macro AMBIENT_COL_DEFAULT make_color_rgb(100,100,100)
	#macro LIGHT_RADIUS_DEFAULT 100 
	//display
	#macro DISPLAY_SCALE 1 //set to lower value if smaller screen is desired
	#macro FULLSCREEN false //set full-screen: true/false
	#macro ANTI_ALIASING 0 //set AA level: 0, 2, 4, or 8
	#macro VSYNC true //set VSYNC: true/false
	//camera
	#macro CAM_POV_MOVE_SPEED 1 //move speed in POV mode
	#macro CAM_POV_Z_OFFSET 16 //vertical offset for POV camera
	#macro LOOK_SENSITIVITY 0.05 //lower values, smoother look sensitivity
	//debug
	#macro DEBUG_OVERLAY true //show debug overlay
	
#endregion

#region Utility Macros (you may change but don't)

	//Stencil buffer stuff
	#macro STENCIL_REF_VAL 0 //stencil buffer reference value 
	//Geometry stuff
	#macro BLOCK_SIZE 8 //block size
	#macro BLOCK_SIZE_HALF 4 //block size/2 (because forward slashes are a precious resource)
	//Vertex buffer stride stuff
	#macro VERTEX_X_OFFSET 0
	#macro VERTEX_Y_OFFSET 4
	#macro VERTEX_Z_OFFSET 8
	#macro VERTEX_NX_OFFSET 12
	#macro VERTEX_NY_OFFSET 16
	#macro VERTEX_NZ_OFFSET 20
	//Camera stuff
	#macro X_UP 1 //x-up direction
	#macro Y_UP 1 //y-up direction
	#macro Z_UP 1 //z-up direction
	
#endregion 

#region Adjust Display

var _w = display_get_width()*DISPLAY_SCALE;
var _h = display_get_height()*DISPLAY_SCALE;
window_set_size(_w,_h); //set window size
surface_resize(application_surface,_w,_h); //set application surface size
display_reset(ANTI_ALIASING,VSYNC);

//toggle full-screen or screen center
if(FULLSCREEN)
{
	window_set_fullscreen(true);
}	else
{
	call_later(10,time_source_units_frames,window_center);
}

#endregion

#region Toggles

//(F2) Rendering View
enum debug_renders 
{
	none, //no debug rendering (regular rendering)
	normals, //render normals
	shadow_volumes, //render shadow volume geometry
	length,
}
debug_render = debug_renders.none; //default to no debug rendering
debug_light_source_idx = 0; //light source index

//(F3) Shadow Volume rendering technique:
enum shadow_volumes_render_techniques
{
	depth_pass, //Depth-Pass (Z-Pass) requires less geometry but will invert shadows if camera is inside shadow volume
	depth_fail, //Depth-Fail (Z-Fail) requires light and dark caps (duplicate model geometry) but allows camera to be inside shadow volume.
	length,
}
shadow_volumes_render_technique = shadow_volumes_render_techniques.depth_fail; //default to depth fail

//(F4) Camera View Type
enum camera_types
{
	orbit, //camera orbits
	POV, //first-person POV
	length,
}
camera_type = camera_types.orbit; //default Orbit

#endregion

#region Camera

camera = -1; //camera index
look_enabled = true; //look-enable flag (toggle with tab)
look_sensitivity = LOOK_SENSITIVITY; //look sensitivity
cam_x = 0; //camera position x
cam_y = 0; //camera position y
cam_z = 0; //camera position z
xto = 0; //xto for matrix_build_lookat
yto = 0; //yto for matrix_build_lookat
zto = 0; //zto for matrix_build_lookat
xfrom = 0; //xfrom for matrix_build_lookat
yfrom = 0; //yfrom for matrix_build_lookat
zfrom = 80; //zfrom for matrix_build_lookat
zfrom_target = 80; //zfrom target for smooth lerp
rad = 100; //radius
rad_target = 100; //radius target for smooth lerp
look_dir = 135; //look direction
look_dir_target = 135; //look direction target for smooth lerp
look_pitch = 0; //look pitch
look_pitch_target = 0; //look pitch target for smooth lerp

//camera matrices
cam_view_matrix = 0; //camera view matrix
cam_proj_matrix = 0; //camera projection matrix
cam_proj_bias_matrix = 0; //camera biased projection matrix (slightly different zfar value to combat z-fighting of shadow volumes with geometry)

#endregion

#region Lights
ambient_col = AMBIENT_COL_DEFAULT; //ambient color

function light(_x,_y,_z,_radius,_color) constructor
{
	x = _x; //position x
	y = _y; //position y
	z = _z; //position z
	radius = _radius; //radius
	color = _color; //color
	idx = 0; //index
	
	enabled = true; //enable flag (unused)
	update = function(){}; //update method run each step (unused)
}
lights = []; //array to hold light structs

#endregion

#region Define Block and Skybox Geometry 

//main geometry vertex format (skybox and blocks)
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_color();
vertex_format_add_texcoord();
vertex_format = vertex_format_end();

#region Create Skybox

var _x = 0;
var _y = 0;
var _z = 0;
var _color = c_white; //default color

vbuff_skybox = vertex_create_buffer();
vertex_begin(vbuff_skybox, vertex_format);

//zmin (floor)
_z = 0;
for(var _ii = 0; _ii < TILES_X; _ii++)
{
	_x = _ii*BLOCK_SIZE;
	for(var _jj = 0; _jj < TILES_Y; _jj++)
	{
		_y = _jj*BLOCK_SIZE;
		if(random(1) > 0.3)
		{
			var _uvs = sprite_get_uvs(spr_grass,0);	
		}	else
		{
			var _uvs = sprite_get_uvs(spr_dirt,0)
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x,			_y,				 _z,    0, 0, 1, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y,				 _z,    0, 0, 1, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y + BLOCK_SIZE, _z,    0, 0, 1, _ur, _vb, _color, 1);											    
		//bottom triangle													    
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y + BLOCK_SIZE, _z,    0, 0, 1, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y + BLOCK_SIZE, _z,    0, 0, 1, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y,				 _z,    0, 0, 1, _ul, _vt, _color, 1);
	}
}

//zmax (ceiling)
_z = TILES_Z*BLOCK_SIZE;
for(var _ii = 0; _ii < TILES_X; _ii++)
{
	_x = _ii*BLOCK_SIZE;
	for(var _jj = 0; _jj < TILES_Y; _jj++)
	{
		_y = _jj*BLOCK_SIZE;
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_stone,0);
				break;
			}
			case 1: 
			{
				var _uvs = sprite_get_uvs(spr_dirt,0);
				break;
			}
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,	_y,				 _z,    0, 0, -1, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y,				 _z,    0, 0, -1, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y + BLOCK_SIZE, _z,    0, 0, -1, _ur, _vb, _color, 1);											    
		//bottom triangle																   
		vertex_add_point(vbuff_skybox, _x,			_y + BLOCK_SIZE, _z,    0, 0, -1, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,	_y + BLOCK_SIZE, _z,    0, 0, -1, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,	_y,				 _z,    0, 0, -1, _ul, _vt, _color, 1);
	}
}

//ymin wall
_y = 0;
for(var _ii = 0; _ii < TILES_X; _ii++)
{
	_x = _ii*BLOCK_SIZE;
	for(var _kk = 0; _kk < TILES_Z; _kk++)
	{
		_z = _kk*BLOCK_SIZE;
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_stone,0);
				break;
			}
			case 1: 
			{
				var _uvs = sprite_get_uvs(spr_dirt,0);
				break;
			}
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x,			_y,	_z+BLOCK_SIZE,    0, 1, 0, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y,	_z+BLOCK_SIZE,    0, 1, 0, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y,	_z,				  0, 1, 0, _ur, _vb, _color, 1);											    
		//bottom triangle													   
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE, _y, _z,			      0, 1, 0, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y, _z,               0, 1, 0, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x,			_y,	_z+BLOCK_SIZE,    0, 1, 0, _ul, _vt, _color, 1);
	}
}

//ymax wall
_y = TILES_Y*BLOCK_SIZE;
for(var _ii = 0; _ii < TILES_X; _ii++)
{
	_x = _ii*BLOCK_SIZE;
	for(var _kk = 0; _kk < TILES_Z; _kk++)
	{
		_z = _kk*BLOCK_SIZE;
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_stone,0);
				break;
			}
			case 1: 
			{
				var _uvs = sprite_get_uvs(spr_dirt,0);
				break;
			}
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,_y, _z+BLOCK_SIZE,    0, -1, 0, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x,		   _y, _z+BLOCK_SIZE,    0, -1, 0, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x,		   _y, _z,				 0, -1, 0, _ur, _vb, _color, 1);											    
		//bottom triangle												   
		vertex_add_point(vbuff_skybox, _x,		   _y, _z,			     0, -1, 0, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,_y, _z,               0, -1, 0, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x+BLOCK_SIZE,_y, _z+BLOCK_SIZE,    0, -1, 0, _ul, _vt, _color, 1);
	}
}

//xmin wall
_x = 0;
for(var _jj = 0; _jj < TILES_Y; _jj++)
{
	_y = _jj*BLOCK_SIZE;
	for(var _kk = 0; _kk < TILES_Z; _kk++)
	{
		_z = _kk*BLOCK_SIZE;
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_stone,0);
				break;
			}
			case 1: 
			{
				var _uvs = sprite_get_uvs(spr_dirt,0);
				break;
			}
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE,	_z+BLOCK_SIZE,   1, 0, 0, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y,			_z+BLOCK_SIZE,   1, 0, 0, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y,			_z,				 1, 0, 0, _ur, _vb, _color, 1);											    
		//bottom triangle			 										   
		vertex_add_point(vbuff_skybox, _x, _y,			_z,				 1, 0, 0, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE, _z,              1, 0, 0, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE, _z+BLOCK_SIZE,   1, 0, 0, _ul, _vt, _color, 1);
	}
}

//xmax wall
_x = TILES_X*BLOCK_SIZE;
for(var _jj = 0; _jj < TILES_Y; _jj++)
{
	_y = _jj*BLOCK_SIZE;
	for(var _kk = 0; _kk < TILES_Z; _kk++)
	{
		_z = _kk*BLOCK_SIZE;
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_stone,0);
				break;
			}
			case 1: 
			{
				var _uvs = sprite_get_uvs(spr_dirt,0);
				break;
			}
		}
		
		var _ul = _uvs[0];
		var _vt = _uvs[1];
		var _ur = _uvs[2];
		var _vb = _uvs[3];
		
		//top triangle
		vertex_add_point(vbuff_skybox, _x, _y,			_z+BLOCK_SIZE,   -1, 0, 0, _ul, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE,	_z+BLOCK_SIZE,   -1, 0, 0, _ur, _vt, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE,	_z,				 -1, 0, 0, _ur, _vb, _color, 1);											    
		//bottom triangle			 								   
		vertex_add_point(vbuff_skybox, _x, _y+BLOCK_SIZE,	_z,				 -1, 0, 0, _ur, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y,			_z,              -1, 0, 0, _ul, _vb, _color, 1);
		vertex_add_point(vbuff_skybox, _x, _y,			_z+BLOCK_SIZE,   -1, 0, 0, _ul, _vt, _color, 1);
	}
}
vertex_end(vbuff_skybox);

#endregion

#region Create Block template

block = vertex_create_buffer();
//origin
var _x = 0;
var _y = 0;
var _z = 0;
//normal vector positive directions
var _x_up = X_UP;
var _y_up = Y_UP;
var _z_up = Z_UP;
//uvs
var _uvs = sprite_get_uvs(spr_stone,0);
var _ul = _uvs[0];
var _vt = _uvs[1];
var _ur = _uvs[2];
var _vb = _uvs[3];
vertex_begin(block, vertex_format);

	//Top 
		//top triangle
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ul, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ur, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ur, _vb, _color, 1);																	    
		//bottom triangle													  
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ur, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ul, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, 0, _z_up, _ul, _vt, _color, 1);
	//Bottom 
		//top triangle
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ul, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ur, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ur, _vb, _color, 1);																	    
		//bottom triangle												    
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ur, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ul, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, 0, -_z_up, _ul, _vt, _color, 1);
	//Front
		//top triangle
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, _y_up, 0, _ul, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, _y_up, 0, _ur, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, _y_up, 0, _ur, _vb, _color, 1);																	    
		//bottom triangle												  							 
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, _y_up, 0, _ur, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, _y_up, 0, _ul, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, _y_up, 0, _ul, _vt, _color, 1);
	//Back
		//top triangle
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, -_y_up, 0, _ul, _vt, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, -_y_up, 0, _ur, _vt, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, -_y_up, 0, _ur, _vb, _color, 1);																	    
		//bottom triangle												  							 	
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, -_y_up, 0, _ur, _vb, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    0, -_y_up, 0, _ul, _vb, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    0, -_y_up, 0, _ul, _vt, _color, 1);
	//Right
		//top triangle
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    _x_up, 0, 0, _ul, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    _x_up, 0, 0, _ur, _vt, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    _x_up, 0, 0, _ur, _vb, _color, 1);																	    
		//bottom triangle											  							  
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    _x_up, 0, 0, _ur, _vb, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    _x_up, 0, 0, _ul, _vb, _color, 1);
		vertex_add_point(block, _x + BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    _x_up, 0, 0, _ul, _vt, _color, 1);
	//Left
		//top triangle
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ul, _vt, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ur, _vt, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ur, _vb, _color, 1);																	    
		//bottom triangle								  							  				
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y + BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ur, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z - BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ul, _vb, _color, 1);
		vertex_add_point(block, _x - BLOCK_SIZE_HALF, _y - BLOCK_SIZE_HALF, _z + BLOCK_SIZE_HALF,    -_x_up, 0, 0, _ul, _vt, _color, 1);
		
vertex_end(block);

#endregion

#endregion

#region Define Shadow Volume Geometry

//shadow volume vertex format
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_color(); //***necessary?
shadow_vertex_format = vertex_format_end();

//calculate shadow volume geometry from block geometry
	//Description:
	//This algorithm reads through the geometry vertex buffer information to find silhouette-forming edges shared by two triangles.
	//These are edges whereby it's posible that one triangle can face a light source while the other does not.
	//This algorithm will also discard non-silhouette-forming edges, which are: edges shared by coplanar triangles, or edges that form a concave shape on the geometry's exterior
	//For best results, the geometry being analyzed should be 2-manifold, meaning a closed ("water-tight") mesh where each edge is formed between exactly two triangles.
	//This has been setup specifically for the vertex format in-use in this example but can be amended for other vertex formats as long as they contain position and normal values.
	//Note: This has not been optimized here.

var _info = vertex_format_get_info(vertex_format); //get vertex format information
var _vertex_size = _info[$ "stride"]; //get vertex size from vertex format info
var _triangle_size = _vertex_size*3; //calculate triangle size from vertex size (A TRIANGLE HAS 3 CORNERS, DONT BE TOO SHOOK'D)
var _buffer_shadows_vertex_buffer = buffer_create(720, buffer_grow, 1); //create a grow buffer (instead of guessing size, just allow it to grow)
var _buffer_vertex_buffer = buffer_create_from_vertex_buffer(block, buffer_fixed, 1); //extract vertex buffer data to a regular buffer to process
var _buffer_size = buffer_get_size(_buffer_vertex_buffer); //size of vertex buffer
var _num_triangles = _buffer_size/_triangle_size; //number of triangles in vertex buffer

var _num_edges = 0; //total number of silhouette-forming edges in shadow volume buffer
var _num_useless_edges = 0; //total number of non-silhouette-forming edges in shadow volume buffer
var _struct_edge_graph = 0; //edge graph
var _buff_read_pos = 0; //buffer read position

for (var _ii = 0; _ii < _num_triangles; _ii++)
{	
	_buff_read_pos = _ii*_triangle_size; //advance buffer read position to next triangle
	
	var _pos1 = _buff_read_pos; //store buffer read position
	var _xA = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_X_OFFSET, buffer_f32));
	var _yA = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Y_OFFSET, buffer_f32));
	var _zA = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Z_OFFSET, buffer_f32));
	var _nxA = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NX_OFFSET, buffer_f32);
	var _nyA = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NY_OFFSET, buffer_f32);
	var _nzA = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NZ_OFFSET, buffer_f32);
	
	//-0's shouldn't be a problem, but they bug me
	_nxA = _nxA == -0 ? 0 : _nxA;
	_nyA = _nyA == -0 ? 0 : _nyA;
	_nzA = _nzA == -0 ? 0 : _nzA;
	
	_buff_read_pos += _vertex_size; //advance to next vertex
	
	var _pos2 = _buff_read_pos; //store buffer read position
	var _xB = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_X_OFFSET, buffer_f32));
	var _yB = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Y_OFFSET, buffer_f32));
	var _zB = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Z_OFFSET, buffer_f32));
	var _nxB = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NX_OFFSET, buffer_f32);
	var _nyB = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NY_OFFSET, buffer_f32);
	var _nzB = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NZ_OFFSET, buffer_f32);
	
	//-0's shouldn't be a problem, but they bug me
	_nxB = _nxB == -0 ? 0 : _nxB;
	_nyB = _nyB == -0 ? 0 : _nyB;
	_nzB = _nzB == -0 ? 0 : _nzB;
	
	_buff_read_pos += _vertex_size; //advance to next vertex
	
	var _pos3 = _buff_read_pos; //store buffer read position
	var _xC = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_X_OFFSET, buffer_f32));
	var _yC = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Y_OFFSET, buffer_f32));
	var _zC = round(buffer_peek(_buffer_vertex_buffer, _buff_read_pos + VERTEX_Z_OFFSET, buffer_f32));
	var _nxC = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NX_OFFSET, buffer_f32);
	var _nyC = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NY_OFFSET, buffer_f32);
	var _nzC = buffer_peek(_buffer_vertex_buffer,	   _buff_read_pos + VERTEX_NZ_OFFSET, buffer_f32);
	
	//-0's shouldn't be a problem, but they bug me
	_nxC = _nxC == -0 ? 0 : _nxC;
	_nyC = _nyC == -0 ? 0 : _nyC;
	_nzC = _nzC == -0 ? 0 : _nzC;
	
	//write triangle into shadow volume buffer
	//Triangle 1
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzA);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,255); //extrudable cap condition
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
		
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzC);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,255); //extrudable cap condition
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
		
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzB);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,255); //extrudable cap condition
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
	buffer_write(_buffer_shadows_vertex_buffer,buffer_u8,0);
		
	//create unique hashes per triangle edge to find other triangles that 
	var _hash1 = string_join(",",string(min(_xA,_xB)),string(max(_xA,_xB)),string(min(_yA,_yB)),string(max(_yA,_yB)),string(min(_zA,_zB)),string(max(_zA,_zB)));
	var _hash2 = string_join(",",string(min(_xB,_xC)),string(max(_xB,_xC)),string(min(_yB,_yC)),string(max(_yB,_yC)),string(min(_zB,_zC)),string(max(_zB,_zC)));
	var _hash3 = string_join(",",string(min(_xC,_xA)),string(max(_xC,_xA)),string(min(_yC,_yA)),string(max(_yC,_yA)),string(min(_zC,_zA)),string(max(_zC,_zA)));
	
	//prep to iterate through edges
	var buffPos1 = [_pos1, _pos2, _pos3];
	var buffPos2 = [_pos2, _pos3, _pos1];
	var buffPos3 = [_pos3, _pos1, _pos2];
	var _xV1 = [_xA, _xB, _xC];
	var _xV2 = [_xB, _xC, _xA];
	var _xV3 = [_xC, _xA, _xB];
	var _yV1 = [_yA, _yB, _yC];
	var _yV2 = [_yB, _yC, _yA];
	var _yV3 = [_yC, _yA, _yB];
	var _zV1 = [_zA, _zB, _zC];
	var _zV2 = [_zB, _zC, _zA];
	var _zV3 = [_zC, _zA, _zB];
	var _hashes = [_hash1, _hash2, _hash3];
	
	var _nx, _ny, _nz;
	var _x1A, _x2A, _y1A, _y2A, _z1A, _z2A, _normXA, _normYA, _normZA, _normXB, _normYB, _normZB;
	var edgeVecX, edgeVecY, edgeVecZ, _mag, arrayColEncode;
	var arrayEdgeNode;
	var nx_col1, ny_col1, nz_col1;
	var nx_col2, ny_col2, nz_col2;

	for (var _jj = 0; _jj < 3; _jj++)
	{
		var _hash = _hashes[_jj]; //get jth edge in triangle

		arrayEdgeNode = _struct_edge_graph[$ _hash];
		if (is_undefined(arrayEdgeNode))
		{
			arrayEdgeNode = array_create(6, -1);
			arrayEdgeNode[0] = buffPos1[_jj];
			arrayEdgeNode[1] = buffPos2[_jj];
			arrayEdgeNode[2] = buffPos3[_jj];
			_struct_edge_graph[$ _hash] = arrayEdgeNode;
		}	else
		{
			if (arrayEdgeNode[3] != -1) //if a second edge already exists, remove from edge graph. This shouldn't happen as every edge should only be shared by exactly 2 triangles
			{
				variable_struct_remove(_struct_edge_graph, _hash);
				show_debug_message("Shadow Volume construction error: edge shared by more than two triangles. Ensure main geometry is 2-manifold.")
			}	else
			{
				//Read normals from other triangle sharing edge
				_nx = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NX_OFFSET, buffer_f32);
				_ny = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NY_OFFSET, buffer_f32);
				_nz = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NZ_OFFSET, buffer_f32);
						
				var _nAdotV13 = dot_product_3d_normalized(_nx,_ny,_nz,(_xV3[_jj] - _xV1[_jj]),(_yV3[_jj] - _yV1[_jj]),(_zV3[_jj] - _zV1[_jj])); //determine if triangle is a possible silhouette edge
				if(_nAdotV13 >= 0.0) //remove edges shared by coplanar triangles or concave edges that are not silhouette forming
				{
					_num_useless_edges++; //increment number of non-silhouette forming edges removed
					arrayEdgeNode = -1;
					variable_struct_remove(_struct_edge_graph, _hash); //remove edge from graph
				}	else
				{
					_num_edges++; //increment number of potential silhouette edges found
						
					//store bufffer positions in edge node array
					arrayEdgeNode[3] = buffPos1[_jj];
					arrayEdgeNode[4] = buffPos2[_jj];
					arrayEdgeNode[5] = buffPos3[_jj];
						
					//read in edge positions and normals (maintain winding order)
					//first vertex of edge
					_x1A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_X_OFFSET, buffer_f32);
					_y1A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_Y_OFFSET, buffer_f32);
					_z1A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_Z_OFFSET, buffer_f32);
						
					//normal of triangle 1
					_normXA = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NX_OFFSET, buffer_f32);
					_normYA = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NY_OFFSET, buffer_f32);
					_normZA = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[0] + VERTEX_NZ_OFFSET, buffer_f32);
						
					//second vertex of edge
					_x2A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[1] + VERTEX_X_OFFSET, buffer_f32);
					_y2A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[1] + VERTEX_Y_OFFSET, buffer_f32);
					_z2A = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[1] + VERTEX_Z_OFFSET, buffer_f32);
							
					//normal of triangle 2
					_normXB = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[3] + VERTEX_NX_OFFSET, buffer_f32);
					_normYB = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[3] + VERTEX_NY_OFFSET, buffer_f32);
					_normZB = buffer_peek(_buffer_vertex_buffer, arrayEdgeNode[3] + VERTEX_NZ_OFFSET, buffer_f32);
						
					//Write extrudable quad to shadow volume buffer
					//Triangle 1
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 

					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A); 
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 
            
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A); 
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 
								
					//Triangle 2
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A); 
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 
								
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 
								
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y1A); 
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z1A);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZA);
					buffer_write(_buffer_shadows_vertex_buffer,buffer_u32,0); 
								
					variable_struct_remove(_struct_edge_graph, _hash);
				}
			}
		}
	}
}
		
show_debug_message($"num silhouette edges: {_num_edges}");
show_debug_message($"num coplanar/non-silhouette edges removed: {_num_useless_edges}");

shadowVBuffer = vertex_create_buffer_from_buffer(_buffer_shadows_vertex_buffer, shadow_vertex_format);


#region Drawing Methods

//Render Ambient Pass
render_ambient_pass = function()
{
	draw_clear_alpha(c_purple,0.0); //clear surface color and alpha
	gpu_set_zwriteenable(true); //enable depth buffer writing
	gpu_set_ztestenable(true); //enable depth testing
	gpu_set_zfunc(cmpfunc_lessequal); //default depth testing
	gpu_set_cullmode(cull_counterclockwise); //cull counterclockwise geometry (back-faces in this case)
	gpu_set_colorwriteenable(true,true,true,true); //enable color and alpha writing
	draw_set_lighting(true); //enable lighting (ambient only)
	draw_light_define_ambient(ambient_col); //set ambient color
	
		//Render geometry to depth buffer for shadow volumes to depth-test
		with (objCube){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
	
	draw_light_define_ambient(c_black);	//set ambient to black (no ambient) for future passes involving lighting
	draw_set_lighting(false); //disable lighting
	
	
}

//Render Shadow Volumes to surface (pass in light source)
render_shadow_volumes = function(_light)
{
	//Shadow Volume Rendering
	gpu_set_zwriteenable(false); //disable depth writing but keep depth testing enabled
	gpu_set_colorwriteenable(false,false,false,false); //disable color and alpha writing
	//Stencil buffer setup
	gpu_set_stencil_enable(true); //enable stencil buffer
	gpu_set_stencil_func(cmpfunc_always); //set to always pass stencil test if depth test is passed
	gpu_set_stencil_pass(stencilop_keep); //keep (default)
	gpu_set_stencil_fail(stencilop_keep); //keep (default)
	gpu_set_stencil_depth_fail(stencilop_keep); //keep (default)
	draw_clear_stencil(STENCIL_REF_VAL); //clear stencil buffer to reference value
	gpu_set_stencil_ref(STENCIL_REF_VAL); //set stencil reference value

	////Apply projection matrix with bias (offset depth of shadow volumes slightly to avoid z-clipping)
	camera_set_proj_mat(camera, cam_proj_bias_matrix);
	camera_apply(camera);

	//Render shadow volumes using either depth-pass or depth-fail technique
	switch(shadow_volumes_render_technique)
	{
		//Depth Pass:
		case shadow_volumes_render_techniques.depth_pass:
		{
			shader_set(sh_render_shadow_volumes);
			//gpu_set_zfunc(cmpfunc_less); //default depth testing
			//for(var _ii = 0; _ii < NUM_LIGHTS; _ii++)
			//{
				var _uniform = shader_get_uniform(sh_render_shadow_volumes, "LightPos");
				var _eye = shader_get_uniform(sh_render_shadow_volumes, "Eye");
				shader_set_uniform_f_array(_uniform, [_light.x,_light.y,_light.z]);
				shader_set_uniform_f_array(_eye,[xfrom,yfrom,zfrom]); //***unnecessary
			
					//render front-facing shadow volume polygons
					gpu_set_cullmode(cull_counterclockwise);
					gpu_set_stencil_pass(stencilop_incr); //increment
					with(objCube){drawSelfShadow();}
		
					//render rear-facing shadow volume polygons
					gpu_set_cullmode(cull_clockwise);
					gpu_set_stencil_pass(stencilop_decr); //decrement
					with(objCube){drawSelfShadow();}
					matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
			//}
			shader_reset();
			gpu_set_stencil_pass(stencilop_keep); //reset to default (keep)
			break;
		}
	
		//Depth Fail:
		case shadow_volumes_render_techniques.depth_fail:
		{
			shader_set(sh_render_shadow_volumes);
				var _uniform = shader_get_uniform(sh_render_shadow_volumes, "LightPos");
				var _eye = shader_get_uniform(sh_render_shadow_volumes, "Eye");
				shader_set_uniform_f_array(_uniform, [_light.x,_light.y,_light.z]);
				shader_set_uniform_f_array(_eye,[xfrom,yfrom,zfrom]);
			
					//render front-facing shadow volume polygons
					gpu_set_cullmode(cull_clockwise);
					gpu_set_stencil_depth_fail(stencilop_incr); //increment
					with(objCube){drawSelfShadow();}
			
					//render rear-facing shadow volume polygons
					gpu_set_cullmode(cull_counterclockwise);
					gpu_set_stencil_depth_fail(stencilop_decr); //decrement
					with(objCube){drawSelfShadow();}
					matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)

			shader_reset();
			gpu_set_stencil_depth_fail(stencilop_keep); //reset to default (keep)
			break;
		}
	}
}

//render lighting pass (pass in light source)
render_lighting_pass = function(_light)
{
	//Re-apply regular camera settings
	camera_set_proj_mat(camera, cam_proj_matrix);
	camera_apply(camera);

	gpu_set_colorwriteenable(true,true,true,true); //enable color and alpha writing
	//gpu_set_zwriteenable(true); //enable depth writing
	gpu_set_ztestenable(true); //enable depth testing
	gpu_set_cullmode(cull_counterclockwise); //set cull mode to counterclockwise (back-faces)
	gpu_set_stencil_ref(STENCIL_REF_VAL);
	
		draw_set_lighting(true); //reactivate lighting (ambient term should still be set to c_black, meaning no additional ambient light is rendered)
		draw_light_define_point(_light.idx, _light.x,_light.y,_light.z, _light.radius, _light.color); //define point source from light struct
		draw_light_enable(_light.idx, true); //enable light source
	
		//Render unshaded geometry
		gpu_set_stencil_func(cmpfunc_equal);
		gpu_set_blendmode(bm_add); //set additive blend mode
		with (objCube){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		//gpu_set_blendmode(bm_normal);
	
		
	
		//Render shaded geometry
		gpu_set_stencil_func(cmpfunc_notequal);
		//shader_set(shd_render_shaded);
		gpu_set_blendmode(bm_subtract);
		with (objCube){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		gpu_set_blendmode(bm_normal);
		//shader_reset();
		
		draw_light_enable(_light.idx,false); //disable point source
		draw_set_lighting(false); //disable lighting 

	//reset for drawing main surface
	gpu_set_stencil_enable(false); //disable stencil test	
}

#endregion

