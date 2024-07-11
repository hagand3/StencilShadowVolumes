

//TODO:
	//freeze vertex buffers [/]
	//build walls and ceiling [/]
	
//Optimizations:
	//Extend shadow volumes only as far as light radius
	
//Model requirements:
	//composed of triangles (duh)
	//closed (2-manifold) geometry
	//consistent winding direction
	
//Experimental:
	//Soft shadows through clustered light sources
	//Soft shadows through shadow volume jittering

//globals
global.time = 0;

//Macros (change these as you see fit)
	#macro NUM_CUBES 100
	#macro NUM_LIGHTS 1
	#macro BLOCK_MIN_Z 20 //min z spawn position for blocks
	#macro BLOCK_MAX_Z 60 //max z spawn position for blocks
	#macro TILES_X 50 //Area x dimension
	#macro TILES_Y 50 //Area y dimension
	#macro TILES_Z 50 //Area z dimension
	//display
	#macro DISPLAY_SCALE 1 //set to lower value if smaller screen is desired
	#macro FULLSCREEN true //set full-screen: true/false
	#macro ANTI_ALIASING 0 //set AA level: 0, 2, 4, or 8
	#macro VSYNC true //set VSYNC: true/false
	//camera
	#macro CAM_POV_Z_OFFSET 16 //vertical offset for POV camera

//Utility Macros (you may change but don't)
	#macro BLOCK_SIZE 8 //block size
	#macro BLOCK_SIZE_HALF 4 //block size/2 (because forward slashes are a precious resource)

//Adjust Display
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
	call_later(30,time_source_units_frames,window_center);
}

//toggles:

//(F2) Rendering View
	//Regular (none)
	//Normals
	//Shadow Volume geometry (partially extruded)
enum debug_renders 
{
	none,
	normals,
	shadow_volumes,
	length,
}
debug_render = debug_renders.none;

//(F3) Shadow Volume rendering technique:
	//Z-Pass requires less geometry but will invert shadows if camera is inside shadow volume
	//Z-Fail requires light and dark caps (duplicate model geometry) but allows camera to be inside shadow volume.
enum shadow_volumes_render_techniques
{
	depth_pass,
	depth_fail,
	length,
}
shadow_volumes_render_technique = shadow_volumes_render_techniques.depth_pass

//(F4) Camera View Type (orbiting or POV)
enum camera_types
{
	orbit,
	POV,
	length,
}
camera_type = camera_types.POV;
cam_x = 0;
cam_y = 0;
cam_z = 0;
rad = 100;
look_dir = 0;
look_pitch = 0;


enum light_source_types
{
	single,
	multiple,
	length,
}
light_source_type = light_source_types.single
num_lights = NUM_LIGHTS;

//initialize lights
light_pos = [];
for(var _ii = 0; _ii < num_lights; _ii++)
{
	var _x = random_range(-BLOCK_SIZE*12,BLOCK_SIZE*12);
	var _y = random_range(-BLOCK_SIZE*12,BLOCK_SIZE*12);
	var _z = random_range(BLOCK_MAX_Z+BLOCK_SIZE, BLOCK_MAX_Z+5*BLOCK_SIZE); //lights above all blocks
	light_pos[_ii] = [_x,_y,_z];
}

z = -96;
phase = 0;

xfrom = 0;
yfrom = 0;
zfrom = 80;
cameraMat = 0;
cameraProjMat = 0;
cameraProjMatBias = 0;

modIndex = -1;


gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);

gpu_set_alphatestenable(true);
gpu_set_alphatestref(0.5);

vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_color();
vertex_format_add_texcoord();
vertex_format = vertex_format_end();

vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_color();
shadow_vertex_format = vertex_format_end();



lightArray = [BLOCK_SIZE*TILES_X/2, BLOCK_SIZE*TILES_Y/2, 2*BLOCK_SIZE];

mouseLock = false;

vertexArray = [];
normalArray = [];
materialArray = [];
modelArray = [];


//cube.materialArray = materialArray;

movePitch = 0;
moveDir = 0;

modelMatrix = matrix_build(0, 0, -1, 0, 0, 0, 1, 1, 1);


var _x = 0;
var _y = 0;
var _z = 0;
var _color = c_white; //default color

// Create Box
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
		switch(irandom(1))
		{
			case 0: 
			{
				var _uvs = sprite_get_uvs(spr_grass,0);
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
				var _uvs = sprite_get_uvs(spr_grass,0);
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

//Create block manually
block = vertex_create_buffer();
//origin
var _x = 0;
var _y = 0;
var _z = 0;
//normal vector positive directions
var _z_up = 1;
var _y_up = 1;
var _x_up = 1;
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



hash1 = 0;
hash2 = 0;
hash3 = 0;
structEdgeGraph = 0;

info = vertex_format_get_info(vertex_format);
vertexSize = info[$ "stride"];

//show_debug_message(vertexSize);

triangleSize = vertexSize*3;

//buffShadows = -1;

//if(buffer_exists(buffShadows))
//{
//	buffer_delete(buffShadows);	
//}
trianglesAmount = array_length(vertexArray)/3;
//show_debug_message(trianglesAmount);

buffShadows = buffer_create(720, buffer_grow, 1);
//show_debug_message(cubeBuffer);
//show_debug_message(_size);
model = load_obj("cube.obj", "cube.mtl");
//cubeBuffer = buffer_create_from_vertex_buffer(model, buffer_fixed, 1);
cubeBuffer = buffer_create_from_vertex_buffer(block, buffer_fixed, 1);


bufferSize = buffer_get_size(cubeBuffer);
show_debug_message(bufferSize);

var _numTriangles = bufferSize/triangleSize;
var _num_edges = 0;
buffReadPos = 0;
for (var i = 0; i < _numTriangles; i++){
	
	buffReadPos = i*36*3;
	var _pos1 = buffReadPos;
	var _xA = round(buffer_peek(cubeBuffer, buffReadPos, buffer_f32));
	var _yA = round(buffer_peek(cubeBuffer, buffReadPos+4, buffer_f32));
	var _zA = round(buffer_peek(cubeBuffer, buffReadPos+8, buffer_f32));
	var _nxA = buffer_peek(cubeBuffer, buffReadPos+12, buffer_f32);
	var _nyA = buffer_peek(cubeBuffer, buffReadPos+16, buffer_f32);
	var _nzA = buffer_peek(cubeBuffer, buffReadPos+20, buffer_f32);
	
	_nxA = _nxA == -0 ? 0 : _nxA;
	_nyA = _nyA == -0 ? 0 : _nyA;
	_nzA = _nzA == -0 ? 0 : _nzA;
	
	buffReadPos += 36;
	var _pos2 = buffReadPos;
	var _xB = round(buffer_peek(cubeBuffer, buffReadPos, buffer_f32));
	var _yB = round(buffer_peek(cubeBuffer, buffReadPos+4, buffer_f32));
	var _zB = round(buffer_peek(cubeBuffer, buffReadPos+8, buffer_f32));
	var _nxB = buffer_peek(cubeBuffer, buffReadPos+12, buffer_f32);
	var _nyB = buffer_peek(cubeBuffer, buffReadPos+16, buffer_f32);
	var _nzB = buffer_peek(cubeBuffer, buffReadPos+20, buffer_f32);
	
	_nxB = _nxB == -0 ? 0 : _nxB;
	_nyB = _nyB == -0 ? 0 : _nyB;
	_nzB = _nzB == -0 ? 0 : _nzB;
	
	buffReadPos += 36;
	var _pos3 = buffReadPos;
	var _xC = round(buffer_peek(cubeBuffer, buffReadPos, buffer_f32));
	var _yC = round(buffer_peek(cubeBuffer, buffReadPos+4, buffer_f32));
	var _zC = round(buffer_peek(cubeBuffer, buffReadPos+8, buffer_f32));
	var _nxC = buffer_peek(cubeBuffer, buffReadPos+12, buffer_f32);
	var _nyC = buffer_peek(cubeBuffer, buffReadPos+16, buffer_f32);
	var _nzC = buffer_peek(cubeBuffer, buffReadPos+20, buffer_f32);
	
	_nxC = _nxC == -0 ? 0 : _nxC;
	_nyC = _nyC == -0 ? 0 : _nyC;
	_nzC = _nzC == -0 ? 0 : _nzC;
	
		////write triangle into shadow volume buffer
		//Triangle 1
		buffer_write(buffShadows,buffer_f32,_xA);
		buffer_write(buffShadows,buffer_f32,_yA);
		buffer_write(buffShadows,buffer_f32,_zA);
		buffer_write(buffShadows,buffer_f32,_nxA);
		buffer_write(buffShadows,buffer_f32,_nyA);
		buffer_write(buffShadows,buffer_f32,_nzA);
		buffer_write(buffShadows,buffer_u8,255); //extrudable cap condition
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		
		buffer_write(buffShadows,buffer_f32,_xC);
		buffer_write(buffShadows,buffer_f32,_yC);
		buffer_write(buffShadows,buffer_f32,_zC);
		buffer_write(buffShadows,buffer_f32,_nxC);
		buffer_write(buffShadows,buffer_f32,_nyC);
		buffer_write(buffShadows,buffer_f32,_nzC);
		buffer_write(buffShadows,buffer_u8,255); //extrudable cap condition
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		
		buffer_write(buffShadows,buffer_f32,_xB);
		buffer_write(buffShadows,buffer_f32,_yB);
		buffer_write(buffShadows,buffer_f32,_zB);
		buffer_write(buffShadows,buffer_f32,_nxB);
		buffer_write(buffShadows,buffer_f32,_nyB);
		buffer_write(buffShadows,buffer_f32,_nzB);
		buffer_write(buffShadows,buffer_u8,255); //extrudable cap condition
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		buffer_write(buffShadows,buffer_u8,0);
		
		
		
		
	
	var _hash1 = string_join(",",string(min(_xA,_xB)),string(max(_xA,_xB)),string(min(_yA,_yB)),string(max(_yA,_yB)),string(min(_zA,_zB)),string(max(_zA,_zB)));
	var _hash2 = string_join(",",string(min(_xB,_xC)),string(max(_xB,_xC)),string(min(_yB,_yC)),string(max(_yB,_yC)),string(min(_zB,_zC)),string(max(_zB,_zC)));
	var _hash3 = string_join(",",string(min(_xC,_xA)),string(max(_xC,_xA)),string(min(_yC,_yA)),string(max(_yC,_yA)),string(min(_zC,_zA)),string(max(_zC,_zA)));
			
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

		for (var j = 0; j < 3; j++)
		{
			var _hash = _hashes[j];

			arrayEdgeNode = structEdgeGraph[$ _hash];
				if (is_undefined(arrayEdgeNode)){
					arrayEdgeNode = array_create(6, -1);
					arrayEdgeNode[0] = buffPos1[j];
					arrayEdgeNode[1] = buffPos2[j];
					arrayEdgeNode[2] = buffPos3[j];
					structEdgeGraph[$ _hash] = arrayEdgeNode;
				}
				else
				{
					//if (arrayEdgeNode[3] != -1){
					//	variable_struct_remove(structEdgeGraph, _hash);	
					//}
					//else
					{
						
						_nx = buffer_peek(cubeBuffer, arrayEdgeNode[0]+12, buffer_f32);
						_ny = buffer_peek(cubeBuffer, arrayEdgeNode[0]+16, buffer_f32);
						_nz = buffer_peek(cubeBuffer, arrayEdgeNode[0]+20, buffer_f32);
						
						var _nAdotV13 = dot_product_3d_normalized(_nx,_ny,_nz,(_xV3[j] - _xV1[j]),(_yV3[j] - _yV1[j]),(_zV3[j] - _zV1[j]));
						
						//_normXA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+12, buffer_f32);
						//_normYA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+16, buffer_f32);
						//_normZA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+20, buffer_f32);
						
						//if(_nx == (_xV3[j] - _xV1[j]) and _ny == (_yV3[j] - _yV1[j]) and _nz == (_zV3[j] - _zV1[j]))
						//if(_nx == _normXA and _ny == _normYA and _nz == _normZA)
						if(_nAdotV13 >= 0.0) //remove coplanar edges
						{
							arrayEdgeNode = -1;
							variable_struct_remove(structEdgeGraph, _hash);
						}
						else
						{
							_num_edges++;
							
							arrayEdgeNode[3] = buffPos1[j];
							arrayEdgeNode[4] = buffPos2[j];
							arrayEdgeNode[5] = buffPos3[j];
							variable_struct_remove(structEdgeGraph, _hash);
							
							_x1A = buffer_peek(cubeBuffer, arrayEdgeNode[0]+0, buffer_f32);
							_y1A = buffer_peek(cubeBuffer, arrayEdgeNode[0]+4, buffer_f32);
							_z1A = buffer_peek(cubeBuffer, arrayEdgeNode[0]+8, buffer_f32);
							
							_normXA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+12, buffer_f32);
							_normYA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+16, buffer_f32);
							_normZA = buffer_peek(cubeBuffer, arrayEdgeNode[2]+20, buffer_f32);
							
							_x2A = buffer_peek(cubeBuffer, arrayEdgeNode[1]+0, buffer_f32);
							_y2A = buffer_peek(cubeBuffer, arrayEdgeNode[1]+4, buffer_f32);
							_z2A = buffer_peek(cubeBuffer, arrayEdgeNode[1]+8, buffer_f32);
							
							_normXB = buffer_peek(cubeBuffer, arrayEdgeNode[3]+12, buffer_f32);
							_normYB = buffer_peek(cubeBuffer, arrayEdgeNode[3]+16, buffer_f32);
							_normZB = buffer_peek(cubeBuffer, arrayEdgeNode[3]+20, buffer_f32);
							
							//nx_col1 = (_normXA*0.5+0.5)*255.0
							//ny_col1 = (_normYA*0.5+0.5)*255.0
							//nz_col1 = (_normZA*0.5+0.5)*255.0
							
							//nx_col2 = (_normXB*0.5+0.5)*255.0
							//ny_col2 = (_normYB*0.5+0.5)*255.0
							//nz_col2 = (_normZB*0.5+0.5)*255.0
							
								//var edgeVecX = _x2A - _x1A;
								//var edgeVecY = _y2A - _y1A;
								//var edgeVecZ = _z2A - _z1A;
								//var _mag = sqrt(sqr(edgeVecX) + sqr(edgeVecY) + sqr(edgeVecZ));
								//edgeVecX /= _mag;
								//edgeVecY /= _mag;
								//edgeVecZ /= _mag;
							
							arrayEdgeNode = -1;
							
								//Triangle 1
								buffer_write(buffShadows,buffer_f32,_x1A);
								buffer_write(buffShadows,buffer_f32,_y1A);
								buffer_write(buffShadows,buffer_f32,_z1A);
								buffer_write(buffShadows,buffer_f32,_normXA);
								buffer_write(buffShadows,buffer_f32,_normYA);
								buffer_write(buffShadows,buffer_f32,_normZA);
								buffer_write(buffShadows,buffer_u32,0); 

								buffer_write(buffShadows,buffer_f32,_x2A); 
								buffer_write(buffShadows,buffer_f32,_y2A);
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXA);
								buffer_write(buffShadows,buffer_f32,_normYA);
								buffer_write(buffShadows,buffer_f32,_normZA);
								buffer_write(buffShadows,buffer_u32,0); 
            
								buffer_write(buffShadows,buffer_f32,_x2A);
								buffer_write(buffShadows,buffer_f32,_y2A); 
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u32,0); 
								
								//Triangle 2
								buffer_write(buffShadows,buffer_f32,_x2A);
								buffer_write(buffShadows,buffer_f32,_y2A); 
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u32,0); 
								
								buffer_write(buffShadows,buffer_f32,_x1A);
								buffer_write(buffShadows,buffer_f32,_y1A);
								buffer_write(buffShadows,buffer_f32,_z1A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u32,0); 
								
								buffer_write(buffShadows,buffer_f32,_x1A);
								buffer_write(buffShadows,buffer_f32,_y1A); 
								buffer_write(buffShadows,buffer_f32,_z1A);
								buffer_write(buffShadows,buffer_f32,_normXA);
								buffer_write(buffShadows,buffer_f32,_normYA);
								buffer_write(buffShadows,buffer_f32,_normZA);
								buffer_write(buffShadows,buffer_u32,0); 
								
								////Triangle 1
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);

								//buffer_write(buffShadows,buffer_f32,_x2A); 
								//buffer_write(buffShadows,buffer_f32,_y2A);
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition B
            
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								////Triangle 2
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition B
								
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition B
								
								////Triangle 1
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);

								//buffer_write(buffShadows,buffer_f32,_x2A); 
								//buffer_write(buffShadows,buffer_f32,_y2A);
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
            
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								////Triangle 2
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								
								
								
								
								////Triangle 1
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);

								//buffer_write(buffShadows,buffer_f32,_x2A); 
								//buffer_write(buffShadows,buffer_f32,_y2A);
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
            
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								
								////Triangle 2
								//buffer_write(buffShadows,buffer_f32,_x2A);
								//buffer_write(buffShadows,buffer_f32,_y2A); 
								//buffer_write(buffShadows,buffer_f32,_z2A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,0); //extrudable for condition A
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								
								//buffer_write(buffShadows,buffer_f32,_x1A);
								//buffer_write(buffShadows,buffer_f32,_y1A);
								//buffer_write(buffShadows,buffer_f32,_z1A);
								//buffer_write(buffShadows,buffer_u8,nx_col2);
								//buffer_write(buffShadows,buffer_u8,ny_col2);
								//buffer_write(buffShadows,buffer_u8,nz_col2);
								//buffer_write(buffShadows,buffer_u8,255);
								//buffer_write(buffShadows,buffer_u8,nx_col1);
								//buffer_write(buffShadows,buffer_u8,ny_col1);
								//buffer_write(buffShadows,buffer_u8,nz_col1);
								//buffer_write(buffShadows,buffer_u8,0);
								
						}
					}
				}
			}
		}
		
sizeBuff = buffer_tell(buffShadows);
show_debug_message(sizeBuff);
show_debug_message($"num silhouette edges: {_num_edges}");

shadowSurface = 0;
shadowVBuffer = vertex_create_buffer_from_buffer(buffShadows, shadow_vertex_format);

shadowSurface2 = 0;


//freeze vertex buffers
vertex_freeze(vbuff_skybox);
vertex_freeze(block);

