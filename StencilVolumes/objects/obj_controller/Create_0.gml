

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
zpass_shadow_volume_vertex_buffer = create_shadow_volume_buffer(block,vertex_format,shadow_vertex_format,false); //only edge quads included
zfail_shadow_volume_vertex_buffer = create_shadow_volume_buffer(block,vertex_format,shadow_vertex_format,true); //zfail shadow volumes (includes original geometry as light/dark caps)

#endregion

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
		with (obj_block){drawSelf();}
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
					with(obj_block){drawSelfShadow();}
		
					//render rear-facing shadow volume polygons
					gpu_set_cullmode(cull_clockwise);
					gpu_set_stencil_pass(stencilop_decr); //decrement
					with(obj_block){drawSelfShadow();}
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
					with(obj_block){drawSelfShadow();}
			
					//render rear-facing shadow volume polygons
					gpu_set_cullmode(cull_counterclockwise);
					gpu_set_stencil_depth_fail(stencilop_decr); //decrement
					with(obj_block){drawSelfShadow();}
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
		with (obj_block){drawSelf();}
		matrix_set(matrix_world, matrix_build_identity()); //reset world matrix (each cube sets its own world matrix)
		vertex_submit(vbuff_skybox, pr_trianglelist, sprite_get_texture(spr_grass,0));
		//gpu_set_blendmode(bm_normal);
	
		
	
		//Render shaded geometry
		gpu_set_stencil_func(cmpfunc_notequal);
		//shader_set(shd_render_shaded);
		gpu_set_blendmode(bm_subtract);
		with (obj_block){drawSelf();}
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

