global.time = 0;

#macro NUM_CUBES 10
#macro NUM_LIGHTS 1

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
	var _z = random_range(CUBE_MAX_Z+BLOCK_SIZE, CUBE_MAX_Z+5*BLOCK_SIZE); //lights above all blocks
	light_pos[_ii] = [_x,_y,_z];
}

z = -96;
cameraMat = 0;
cameraProjMat = 0;

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
vertex_format_add_custom(vertex_type_float3,vertex_usage_texcoord);
//vertex_format_add_normal();
vertex_format_add_color();
shadow_vertex_format = vertex_format_end();

xfrom = 0;
yfrom = 0;
zfrom = 0;

lightArray = [1, 1, 1];

mouseLock = false;

vertexArray = [];
normalArray = [];
materialArray = [];
modelArray = [];


//cube.materialArray = materialArray;

movePitch = 0;
moveDir = 0;

modelMatrix = matrix_build(0, 0, -1, 0, 0, 0, 1, 1, 1);


var _num_w = 100; //number of tiles wide for floor
var _num_h = 100; //number of tiles tall for floor
var _w = 8*_num_w;
var _h = 8*_num_h;
var _color = c_white; //default color
#macro BLOCK_SIZE 8 //block size

// Create ground
ground = vertex_create_buffer();
vertex_begin(ground, vertex_format);
for(var _ii = 0, _x; _ii < _num_w; _ii++)
{
	_x = _ii*BLOCK_SIZE;
	for(var _jj = 0, _y; _jj < _num_h; _jj++)
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
		vertex_add_point(ground, _x, _y, 0,                         0, 0, 1,        _ul, _vt,       _color, 1);
		vertex_add_point(ground, _x+BLOCK_SIZE, _y, 0,                 0, 0, 1,        _ur, _vt,       _color, 1);
		vertex_add_point(ground, _x+BLOCK_SIZE, _y + BLOCK_SIZE, 0,       0, 0, 1,        _ur, _vb,       _color, 1);

		//bottom triangle
		vertex_add_point(ground, _x+BLOCK_SIZE, _y + BLOCK_SIZE, 0,       0, 0, 1,        _ur, _vb,       _color, 1);
		vertex_add_point(ground, _x, _y + BLOCK_SIZE, 0,               0, 0, 1,        _ul, _vb,       _color, 1);
		vertex_add_point(ground, _x, _y, 0,                         0, 0, 1,        _ul, _vt,       _color, 1);
	}
}
vertex_end(ground);

////create static block 
//static_block = vertex_create_buffer();
//vertex_begin(ground, vertex_format);

////top
//		//top triangle
//		vertex_add_point(ground, _x, _y, 0,                         0, 0, 1,        _ul, _vt,       _color, 1);
//		vertex_add_point(ground, _x+BLOCK_W, _y, 0,                 0, 0, 1,        _ur, _vt,       _color, 1);
//		vertex_add_point(ground, _x+BLOCK_W, _y + BLOCK_H, 0,       0, 0, 1,        _ur, _vb,       _color, 1);

//		//bottom triangle
//		vertex_add_point(ground, _x+BLOCK_W, _y + BLOCK_H, 0,       0, 0, 1,        _ur, _vb,       _color, 1);
//		vertex_add_point(ground, _x, _y + BLOCK_H, 0,               0, 0, 1,        _ul, _vb,       _color, 1);
//		vertex_add_point(ground, _x, _y, 0,                         0, 0, 1,        _ul, _vt,       _color, 1);



//var s = 128;
//var xtex = room_width / sprite_get_width(sprRock);
//var ytex = room_height / sprite_get_height(sprRock);


//vertex_add_point(ground, 0, 0, 0,                          0, 0, 1,        0, 0,       color, 1);
//vertex_add_point(ground, room_width, 0, 0,                 0, 0, 1,        xtex, 0,       color, 1);
//vertex_add_point(ground, room_width, room_height, 0,       0, 0, 1,        xtex, ytex,       color, 1);

//vertex_add_point(ground, room_width, room_height, 0,       0, 0, 1,        xtex, ytex,       color, 1);
//vertex_add_point(ground, 0, room_height, 0,                0, 0, 1,        0, ytex,       color, 1);
//vertex_add_point(ground, 0, 0, 0,                          0, 0, 1,        0, 0,       color, 1);


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
cubeBuffer = buffer_create_from_vertex_buffer(model, buffer_fixed, 1);


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
	
	buffReadPos += 36;
	var _pos2 = buffReadPos;
	var _xB = round(buffer_peek(cubeBuffer, buffReadPos, buffer_f32));
	var _yB = round(buffer_peek(cubeBuffer, buffReadPos+4, buffer_f32));
	var _zB = round(buffer_peek(cubeBuffer, buffReadPos+8, buffer_f32));
	
	buffReadPos += 36;
	var _pos3 = buffReadPos;
	var _xC = round(buffer_peek(cubeBuffer, buffReadPos, buffer_f32));
	var _yC = round(buffer_peek(cubeBuffer, buffReadPos+4, buffer_f32));
	var _zC = round(buffer_peek(cubeBuffer, buffReadPos+8, buffer_f32));
	
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
						_num_edges++;
						_nx = buffer_peek(cubeBuffer, arrayEdgeNode[0]+12, buffer_f32);
						_ny = buffer_peek(cubeBuffer, arrayEdgeNode[0]+16, buffer_f32);
						_nz = buffer_peek(cubeBuffer, arrayEdgeNode[0]+20, buffer_f32);
						
						var _nAdotV13 = dot_product_3d_normalized(_nx,_ny,_nz,(_xV3[j] - _xV1[j]),(_yV3[j] - _yV1[j]),(_zV3[j] - _zV1[j]));
						
						//if(_nAdotV13 >= 0.0)
						//{
						//	arrayEdgeNode = -1;
						//	variable_struct_remove(structEdgeGraph, _hash);
						//}
						//else
						{
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
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,0); //extrudable for condition A
								buffer_write(buffShadows,buffer_u8,255);
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0);

								buffer_write(buffShadows,buffer_f32,_x2A); 
								buffer_write(buffShadows,buffer_f32,_y2A);
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXA);
								buffer_write(buffShadows,buffer_f32,_normYA);
								buffer_write(buffShadows,buffer_f32,_normZA);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,0); //extrudable for condition A
								buffer_write(buffShadows,buffer_u8,255);
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0); 
            
								buffer_write(buffShadows,buffer_f32,_x2A);
								buffer_write(buffShadows,buffer_f32,_y2A); 
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,255);
								buffer_write(buffShadows,buffer_u8,0); //extrudable for condition B
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0);
								
								//Triangle 2
								buffer_write(buffShadows,buffer_f32,_x2A);
								buffer_write(buffShadows,buffer_f32,_y2A); 
								buffer_write(buffShadows,buffer_f32,_z2A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,255); //extrudable for condition A
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0); 
								
								buffer_write(buffShadows,buffer_f32,_x1A);
								buffer_write(buffShadows,buffer_f32,_y1A);
								buffer_write(buffShadows,buffer_f32,_z1A);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,255);
								buffer_write(buffShadows,buffer_u8,0); //extrudable for condition B
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0); 
								
								buffer_write(buffShadows,buffer_f32,_x1A);
								buffer_write(buffShadows,buffer_f32,_y1A); 
								buffer_write(buffShadows,buffer_f32,_z1A);
								buffer_write(buffShadows,buffer_f32,_normXA);
								buffer_write(buffShadows,buffer_f32,_normYA);
								buffer_write(buffShadows,buffer_f32,_normZA);
								buffer_write(buffShadows,buffer_f32,_normXB);
								buffer_write(buffShadows,buffer_f32,_normYB);
								buffer_write(buffShadows,buffer_f32,_normZB);
								buffer_write(buffShadows,buffer_u8,0); //extrudable for condition A
								buffer_write(buffShadows,buffer_u8,255); //extrudable for condition B
								buffer_write(buffShadows,buffer_u8,0);
								buffer_write(buffShadows,buffer_u8,0); 
							
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


//Create cubes
#macro CUBE_MIN_Z 10
#macro CUBE_MAX_Z 40
repeat(NUM_CUBES)
{
	var _ii = random_range(-5,5);
	var _jj = random_range(-5,5);
	var _z = random_range(CUBE_MIN_Z,CUBE_MAX_Z);
	var _cube = instance_create_depth(BLOCK_SIZE*(15-_ii), BLOCK_SIZE*(15-_jj), 0, objCube);
	_cube.model = model;
	_cube.shadow_vbuff = shadowVBuffer;
	_cube.z = _z;
}

