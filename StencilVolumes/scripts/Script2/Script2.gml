function calculate_terrain_silhouette_edges(argument0){

if(buffer_exists(buff_terrain_shadows))
{
	buffer_delete(buff_terrain_shadows);	
}
buff_terrain_shadows = -1;
buff_terrain_shadows = buffer_create(total_terrain_triangles*12*3*VERTEX_SIZE_XYZ_NORM_NORM_TANGENT_COL,buffer_fixed,1); //worst case size assumption. Every triangle can generate 3 shadow edges, each made of 2 quads (12 vertices)
//buff_terrain_shadows = buffer_create(0,buffer_grow,1);

var _i = argument0[0];
var _j = argument0[1];
var _i_end = argument0[2];
var _j_end = argument0[3];
var _room_w = global.room_w;
var _room_h = global.room_h;

var _to = get_timer();

var _stale_references = [];
for(var _ii = _i_end-1; _ii >= _i; _ii--) //initialize array at room size
{
	for (var _jj = _j_end-1; _jj >= _j; _jj--)
	{
		_stale_references[_ii][_jj] = -1;
	}
}

var _total_deleted = 0;
var _terrain_idx,_num_vertices_in_cell,_num_triangles_in_cell,_ii_jj_encode;
var _x1,_x2,_x3,_y1,_y2,_y3,_z1,_z2,_z3;
var _hash1,_hash2,_hash3;
var _pos1,_pos2,_pos3;
var _buff_cell_read_pos,_buff_curr_read_pos,_current_vertex;
var _x_v1 = [];
var _x_v2 = [];
var _x_v3 = [];
var _y_v1 = [];
var _y_v2 = [];
var _y_v3 = [];
var _z_v1 = [];
var _z_v2 = [];
var _z_v3 = [];
var _hashes = [];
var _buffer_pos1 = [];
var _buffer_pos2 = [];
var _buffer_pos3 = [];
var _nn,_hash,_arr_edge_node,_xa,_ya,_za,_xb,_yb,_zb,_nxa,_nya,_nza,_nAdotV23,_nAdotV13,_normAdotnormB;
var _ff = 10;
var _total_triangles_processed = 0;
var _hashes_added;
var _hashes_to_delete;
var _delta_deleted;
var _struct_edge_graph = {};
var _x1A,_y1A,_z1A,_x2A,_y2A,_z2A,_norm_xA,_norm_yA,_norm_zA,_norm_xB,_norm_yB,_norm_zB,_arr_col_encode,_r,_g,_b,_a,_edge_vector_x,_edge_vector_y,_edge_vector_z,_mag;

for (var _ii = _i; _ii < _i_end; _ii++)
{
	show_debug_message("Constructing Shadow Volumes: " + string(100*(_total_triangles_processed/total_terrain_triangles)) + "% complete. " + "Total Triangles Processed: " + string(_total_triangles_processed) + "/" + string(total_terrain_triangles) + ". Buffer size: " + string(buffer_tell(buff_terrain_shadows)));
	for (var _jj = _j; _jj < _j_end; _jj++)
	{
		//Delete stale hash references
		if(_ii > 1 and _jj > 1)
		{
			_hashes_to_delete = _stale_references[_ii-2][_jj-2];
			if(_hashes_to_delete != -1)
			{
				var _num_before = variable_struct_names_count(_struct_edge_graph);
				var _num_to_delete = array_length(_hashes_to_delete);
				for(var _ll = 0; _ll < _num_to_delete; _ll++)
				{
					var hash_to_delete = _hashes_to_delete[_ll];
					if(variable_struct_exists(_struct_edge_graph,hash_to_delete))
					{
						_arr_edge_node = _struct_edge_graph[$ hash_to_delete];
						_arr_edge_node = -1;
						variable_struct_remove(_struct_edge_graph,hash_to_delete);
					}	
				}
				_stale_references[_ii-2][_jj-2] = -1;
				_delta_deleted = _num_before - variable_struct_names_count(_struct_edge_graph);
				if(_delta_deleted > 0)
				{
					_total_deleted += _delta_deleted;
					//show_debug_message(string(_delta_deleted) + " struct entries deleted. Total deleted: " + string(_total_deleted) + ". Struct size: " + string(variable_struct_names_count(_struct_edge_graph)));
				}
			}
		}
		//
		
		_num_vertices_in_cell = array_num_terrain_vertices_at_ij[_ii][_jj];
		if(_num_vertices_in_cell > 0)
		{
			_hashes_added = [];	
			_current_vertex = 0;
			_num_triangles_in_cell = _num_vertices_in_cell/3;
			_terrain_idx = global.array_terrain_at_ij[TileGridArray.terrain_idx][_ii][_jj]; //read-in terrain idx
			_buff_cell_read_pos = (_ii*_room_h + _jj)*SIZE_VERTEX_PER_CELL; //set buffer read position
		
			if(_terrain_idx == TerrainIdx.DYN_FLAT_1 or _terrain_idx == TerrainIdx.DYN_FLAT_0) //encode dynamic tiles differently (//***FUTUREPROOF: Change to a worldtile struct .isolated_shadow_volumes == true)
			{
				_ii_jj_encode = true;
			}	else
			{
				_ii_jj_encode = false; //default	
			}
			for (var _kk = 0; _kk < _num_triangles_in_cell; _kk++)
			{
				_buff_curr_read_pos = _buff_cell_read_pos + 3*_kk*VERTEX_SIZE_XYZ_NORM_UV_COL_UV_UV_COL;
				_pos1 = _buff_curr_read_pos;
				_x1 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_X_OFFSET,buffer_f32)*_ff)/_ff;
				_y1 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Y_OFFSET,buffer_f32)*_ff)/_ff;
				_z1 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Z_OFFSET,buffer_f32)*_ff)/_ff;
				_buff_curr_read_pos += VERTEX_SIZE_XYZ_NORM_UV_COL_UV_UV_COL;
				_pos2 = _buff_curr_read_pos;
				_x2 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_X_OFFSET,buffer_f32)*_ff)/_ff;
				_y2 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Y_OFFSET,buffer_f32)*_ff)/_ff;
				_z2 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Z_OFFSET,buffer_f32)*_ff)/_ff;
				_buff_curr_read_pos += VERTEX_SIZE_XYZ_NORM_UV_COL_UV_UV_COL;
				_pos3 = _buff_curr_read_pos;
				_x3 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_X_OFFSET,buffer_f32)*_ff)/_ff;
				_y3 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Y_OFFSET,buffer_f32)*_ff)/_ff;
				_z3 = round(buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Z_OFFSET,buffer_f32)*_ff)/_ff;
				
				//if(frac(_x1) == 0.02 or frac(_x2) == 0.02 or frac(_y1) == 0.02 or frac(_y2) == 0.02 or frac(_x1) == 0.98 or frac(_x2) == 0.98 or frac(_y1) == 0.98 or frac(_y2) == 0.98)
				//{
				//	var _debug = true;	
				//	_x3 = buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_X_OFFSET,buffer_f32);
				//	_y3 = buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Y_OFFSET,buffer_f32);
				//	_z3 = buffer_peek(buff_terrain_3D,_buff_curr_read_pos+VERTEX_Z_OFFSET,buffer_f32);
				//}
				
				//Edge graph population
				if(!_ii_jj_encode)
				{
					_hash1 = string_join(",",string(min(_x1,_x2)),string(max(_x1,_x2)),string(min(_y1,_y2)),string(max(_y1,_y2)),string(min(_z1,_z2)),string(max(_z1,_z2))); //hash the edge in a commutable manner (vertex order independent)
					_hash2 = string_join(",",string(min(_x2,_x3)),string(max(_x2,_x3)),string(min(_y2,_y3)),string(max(_y2,_y3)),string(min(_z2,_z3)),string(max(_z2,_z3))); //hash the edge in a commutable manner (vertex order independent)
					_hash3 = string_join(",",string(min(_x3,_x1)),string(max(_x3,_x1)),string(min(_y3,_y1)),string(max(_y3,_y1)),string(min(_z3,_z1)),string(max(_z3,_z1))); //hash the edge in a commutable manner (vertex order independent)
				}	else
				{
					_hash1 = string_join(",",string(min(_x1,_x2)),string(max(_x1,_x2)),string(min(_y1,_y2)),string(max(_y1,_y2)),string(min(_z1,_z2)),string(max(_z1,_z2)),string(_ii),string(_jj)); //hash the edge in a commutable manner (vertex order independent)
					_hash2 = string_join(",",string(min(_x2,_x3)),string(max(_x2,_x3)),string(min(_y2,_y3)),string(max(_y2,_y3)),string(min(_z2,_z3)),string(max(_z2,_z3)),string(_ii),string(_jj)); //hash the edge in a commutable manner (vertex order independent)
					_hash3 = string_join(",",string(min(_x3,_x1)),string(max(_x3,_x1)),string(min(_y3,_y1)),string(max(_y3,_y1)),string(min(_z3,_z1)),string(max(_z3,_z1)),string(_ii),string(_jj)); //hash the edge in a commutable manner (vertex order independent)
				}

				if(_hash1 == _hash2 or _hash1 == _hash3 or _hash2 == _hash3)
				{
					num_self_collisions++;
					var _debug = true;	//self collision
				}
				
				_x_v1 = [_x1,_x2,_x3];
				_x_v2 = [_x2,_x3,_x1];
				_x_v3 = [_x3,_x1,_x2];
				_y_v1 = [_y1,_y2,_y3];
				_y_v2 = [_y2,_y3,_y1];
				_y_v3 = [_y3,_y1,_y2];
				_z_v1 = [_z1,_z2,_z3];
				_z_v2 = [_z2,_z3,_z1];
				_z_v3 = [_z3,_z1,_z2];
				_hashes = [_hash1,_hash2,_hash3];
				_buffer_pos1 = [_pos1,_pos2,_pos3];
				_buffer_pos2 = [_pos2,_pos3,_pos1];
				_buffer_pos3 = [_pos3,_pos1,_pos2];
				_nn = 0;

				repeat(3)
				{
					_hash = _hashes[_nn]; //hash the edge in a commutable manner (vertex order independent)
					_arr_edge_node = _struct_edge_graph[$ _hash]; //get edge node. If node already exists, add this polygon's buffer positions to the node
					if(is_undefined(_arr_edge_node)) //If node doesn't exist, edge node array must be created. node must be pushed to array_local_edges
					{
						//if(_z_v1[_nn] <= 0.2 and _z_v2[_nn] <= 0.2)
						//{
						//	//var _debug = true; // bottom edge (z=0) detected. Results tossed
						//	num_bottom_edges_tossed++;
						//	variable_struct_remove(_struct_edge_graph,_hash);
						//}	else
						//{
							_arr_edge_node = array_create(6,-1); //store first two edge vertices (in order), and then non-edge vertex (for polygon-facing post-culling)
							_arr_edge_node[@ 0] = _buffer_pos1[_nn];
							_arr_edge_node[@ 1] = _buffer_pos2[_nn];
							_arr_edge_node[@ 2] = _buffer_pos3[_nn];
							_struct_edge_graph[$ _hash] = _arr_edge_node; //store _arr_edge_node in _struct_edge_graph
							num_total_edges++;
							array_push(_hashes_added,_hash);
						//}
					}	else
					{
						//var _x11 = buffer_peek(buff_terrain_3D,_arr_edge_node[0],buffer_f32);
						//var _y11 = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+4,buffer_f32);
						//var _z11 = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+8,buffer_f32);
		
						//var _x22 = buffer_peek(buff_terrain_3D,_arr_edge_node[1],buffer_f32);
						//var _y22 = buffer_peek(buff_terrain_3D,_arr_edge_node[1]+4,buffer_f32);
						//var _z22 = buffer_peek(buff_terrain_3D,_arr_edge_node[1]+8,buffer_f32);
		
						//var _x33 = buffer_peek(buff_terrain_3D,_arr_edge_node[2],buffer_f32);
						//var _y33 = buffer_peek(buff_terrain_3D,_arr_edge_node[2]+4,buffer_f32);
						//var _z33 = buffer_peek(buff_terrain_3D,_arr_edge_node[2]+8,buffer_f32);
						//if(_arr_edge_node[3] != -1 or _arr_edge_node[4] != -1 or _arr_edge_node[5] != -1)	
						if(_arr_edge_node[3] != -1)
						{
							//***insert check here to ensure edge is not already present (which would be the case if the degenerate cases are removed from the struct and the surrounding cells are reconstructed)
							//var _x44 = buffer_peek(buff_terrain_3D,_arr_edge_node[3],buffer_f32);
							//var _y44 = buffer_peek(buff_terrain_3D,_arr_edge_node[3]+4,buffer_f32);
							//var _z44 = buffer_peek(buff_terrain_3D,_arr_edge_node[3]+8,buffer_f32);
			
							//var _x55 = buffer_peek(buff_terrain_3D,_arr_edge_node[4],buffer_f32);
							//var _y55 = buffer_peek(buff_terrain_3D,_arr_edge_node[4]+4,buffer_f32);
							//var _z55 = buffer_peek(buff_terrain_3D,_arr_edge_node[4]+8,buffer_f32);
		
							//var _x66 = buffer_peek(buff_terrain_3D,_arr_edge_node[5],buffer_f32);
							//var _y66 = buffer_peek(buff_terrain_3D,_arr_edge_node[5]+4,buffer_f32);
							//var _z66 = buffer_peek(buff_terrain_3D,_arr_edge_node[5]+8,buffer_f32);
							//struct_edge_removal_graph[$ _hash] = true;
							variable_struct_remove(_struct_edge_graph,_hash);
							num_legitimate_collisions++;
							show_debug_message("Legitimate edge hash collision at: (" + string(_ii) + "," + string(_jj) + "). Hash: " + _hash);
							//var _debug = true;	//Collision? These nodes shouldn't be populated unless edge points to more than two triangles somehow
						}	else //Shared edge. Possible silhouette edge. 
						{
							//before populating, check for degenerate cases and remove them
							//https://marctenbosch.com/npr_edges/
							//https://stackoverflow.com/questions/24529677/determining-whether-triangles-are-facing-each-other
							//_xa = floor(buffer_peek(buff_terrain_3D,_arr_edge_node[2],buffer_f32)*_ff)/_ff;
							//_ya = floor(buffer_peek(buff_terrain_3D,_arr_edge_node[2]+4,buffer_f32)*_ff)/_ff;
							//_za = floor(buffer_peek(buff_terrain_3D,_arr_edge_node[2]+8,buffer_f32)*_ff)/_ff;
							//_xb = _x_v3[_nn];
							//_yb = _y_v3[_nn];
							//_zb = _z_v3[_nn];
			
							//read-in normalized normal vectors
							_nxa = buffer_peek(buff_terrain_3D,_arr_edge_node[2]+VERTEX_NORM_X_OFFSET,buffer_f32);
							_nya = buffer_peek(buff_terrain_3D,_arr_edge_node[2]+VERTEX_NORM_Y_OFFSET,buffer_f32);
							_nza = buffer_peek(buff_terrain_3D,_arr_edge_node[2]+VERTEX_NORM_Z_OFFSET,buffer_f32);
			
							//Check dot product between normal of face A with edge vector V12 or V23 (using third vertex position)
							//_nAdotV23 = dot_product_3d_normalized(_nxa,_nya,_nza,(_x_v3[_nn] - _x_v2[_nn]),(_y_v3[_nn] - _y_v2[_nn]),(_z_v3[_nn] - _z_v2[_nn]));
							_nAdotV13 = dot_product_3d_normalized(_nxa,_nya,_nza,(_x_v3[_nn] - _x_v1[_nn]),(_y_v3[_nn] - _y_v1[_nn]),(_z_v3[_nn] - _z_v1[_nn]));
							
							//var _nBdotV23 = dot_product_3d(_nx,_ny,_nz,(_x_v3[_nn] - _x_v2[_nn]),(_y_v3[_nn] - _y_v2[_nn]),(_z_v3[_nn] - _z_v2[_nn]));
							//var _nBdotV31 = dot_product_3d(_nx,_ny,_nz,(_x_v1[_nn] - _x_v3[_nn]),(_y_v1[_nn] - _y_v3[_nn]),(_z_v1[_nn] - _z_v3[_nn]));
							//Dot product between vector from non-edge vertices of face A and B and vector from same points extruded along normal by large amount
							//var _pre_post_extrusion_dotprod =  dot_product_3d_normalized(_xb-_xa,_yb-_ya,_zb-_za,(_xb+_nx*1000000)-(_xa+_nxa*1000000),(_yb+_ny*1000000)-(_ya+_nya*1000000),(_zb+_nz*1000000)-(_za+_nza*1000000));
							
							//_normAdotnormB = dot_product_3d_normalized(_nxa,_nya,_nza,_nx,_ny,_nz);
							
							//if(_pre_post_extrusion_dotprod <= 0.1) //triangles facing each other, valley edge
							//{
							//	_arr_edge_node = -1;
							//	variable_struct_remove(_struct_edge_graph,_hash);
							//	num_degenerate_edges++;
							//	//var _debug = true;
							//}	else
			
			
							//if(_normAdotnormB >= 0.999) //triangles are coplanar (normals parallel)
							if(_nAdotV13 >= 0.0)
							{
								_arr_edge_node = -1;
								variable_struct_remove(_struct_edge_graph,_hash);
								num_degenerate_edges++;
								//var _debug = true;	
							}	else
							{
								_arr_edge_node[@ 3] = _buffer_pos1[_nn];
								_arr_edge_node[@ 4] = _buffer_pos2[_nn];
								_arr_edge_node[@ 5] = _buffer_pos3[_nn];
								num_shared_edges++;
								variable_struct_remove(_struct_edge_graph,_hash);
								
								//-----------------------------------------------------
								//buff_terrain_shadows = -1;
								//buff_terrain_shadows = buffer_create(num_shared_edges*12*VERTEX_SIZE_XYZ_NORM_NORM_TANGENT_COL,buffer_fixed,1);
								
								//copy vertex data into shadow volume edge buffer
								_x1A = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_X_OFFSET,buffer_f32);
								_y1A = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_Y_OFFSET,buffer_f32);
								_z1A = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_Z_OFFSET,buffer_f32);
								//_norm_xA = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_NORM_X_OFFSET,buffer_f32);
								//_norm_yA = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_NORM_Y_OFFSET,buffer_f32);
								//_norm_zA = buffer_peek(buff_terrain_3D,_arr_edge_node[0] + VERTEX_NORM_Z_OFFSET,buffer_f32);
								_norm_xA = _nxa;
								_norm_yA = _nya;
								_norm_zA = _nza;
								_arr_col_encode = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+VERTEX_COL_ENCODE_OFFSET,buffer_u32);
								//_r = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+VERTEX_R_ENCODE_OFFSET,buffer_u8);
								//_g = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+VERTEX_G_ENCODE_OFFSET,buffer_u8);
								//_b = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+VERTEX_B_ENCODE_OFFSET,buffer_u8);
								//_a = buffer_peek(buff_terrain_3D,_arr_edge_node[0]+VERTEX_A_ENCODE_OFFSET,buffer_u8);
								_x2A = buffer_peek(buff_terrain_3D,_arr_edge_node[1] + VERTEX_X_OFFSET,buffer_f32);
								_y2A = buffer_peek(buff_terrain_3D,_arr_edge_node[1] + VERTEX_Y_OFFSET,buffer_f32);
								_z2A = buffer_peek(buff_terrain_3D,_arr_edge_node[1] + VERTEX_Z_OFFSET,buffer_f32);
								_norm_xB = buffer_peek(buff_terrain_3D,_arr_edge_node[3] + VERTEX_NORM_X_OFFSET,buffer_f32);
								_norm_yB = buffer_peek(buff_terrain_3D,_arr_edge_node[3] + VERTEX_NORM_Y_OFFSET,buffer_f32);
								_norm_zB = buffer_peek(buff_terrain_3D,_arr_edge_node[3] + VERTEX_NORM_Z_OFFSET,buffer_f32);
								
								
								_arr_edge_node = -1; //de-reference
								
								_edge_vector_x = _x2A - _x1A;
								_edge_vector_y = _y2A - _y1A;
								_edge_vector_z = _z2A - _z1A;
								_mag = sqrt(sqr(_edge_vector_x) + sqr(_edge_vector_y) + sqr(_edge_vector_z));
								_edge_vector_x /= _mag;
								_edge_vector_y /= _mag;
								_edge_vector_z /= _mag;
			
								//quad 1
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);

			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								//quad 2
								_edge_vector_x = -_edge_vector_x;
								_edge_vector_y = -_edge_vector_y;
								_edge_vector_z = -_edge_vector_z;
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z2A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);
			
								buffer_write(buff_terrain_shadows,buffer_f32,_x1A);
								buffer_write(buff_terrain_shadows,buffer_f32,-_y1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_z1A);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zB);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_xA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_yA);
								buffer_write(buff_terrain_shadows,buffer_f32,_norm_zA);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_x);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_y);
								buffer_write(buff_terrain_shadows,buffer_f32,_edge_vector_z);
								buffer_write(buff_terrain_shadows,buffer_u32,_arr_col_encode);
								//buffer_write(buff_terrain_shadows,buffer_u8,_r);
								//buffer_write(buff_terrain_shadows,buffer_u8,_g);
								//buffer_write(buff_terrain_shadows,buffer_u8,_b);
								//buffer_write(buff_terrain_shadows,buffer_u8,_a);

							}
						}	
					}
					_nn++;
				}

				gc_collect();
				//show_debug_message("Constructing: " + string((get_timer()-_to)) + "useconds");
				//show_debug_message( string(variable_struct_names_count(_struct_edge_graph)));

				//----------------------------------------------------------------------------------------------------------------------
				//
				_current_vertex += 3;
				_total_triangles_processed += 1;
			}
			_stale_references[_ii][_jj] = _hashes_added;
		}	
		else
		{
			continue; //move onto next cell	
		}
	}
}
var _buff_size = buffer_tell(buff_terrain_shadows);
buffer_resize(buff_terrain_shadows,_buff_size);

show_debug_message("Silhouette Edge Struct Population: " + string((get_timer()-_to)/1000000) + "seconds");
show_debug_message("Number of total edges: " + string(num_total_edges));
show_debug_message("Number of bottom edges tossed: " + string(num_bottom_edges_tossed));
show_debug_message("Number of degenerate edges tossed: " + string(num_degenerate_edges));
show_debug_message("Number of isolated edges tossed: " + string(num_isolated_edges));
show_debug_message("Number of self collisions: " + string(num_self_collisions));
show_debug_message("Number of legitimate collisions: " + string(num_legitimate_collisions));
show_debug_message("Number of shared edges: " + string(num_shared_edges));
show_debug_message("Max Number of 3d triangles per cell: " + string(max_num_terrain_3d_vertices_per_cell/3));

}