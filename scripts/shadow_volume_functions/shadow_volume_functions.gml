//Description:
	//This algorithm reads through the geometry vertex buffer information to find silhouette-forming edges shared by two triangles.
	//These are edges whereby it's posible that one triangle can face a light source while the other does not.
	//This algorithm will also discard non-silhouette-forming edges, which are: edges shared by coplanar triangles, or edges that form a concave shape on the geometry's exterior
	//For best results, the geometry being analyzed should be 2-manifold, meaning a closed ("water-tight") mesh where each edge is formed between exactly two triangles.
	//This has been setup specifically for the vertex format in-use in this example but can be amended for other vertex formats as long as they contain position and normal values.
	//Note: This has not been optimized. Can be rewritten to analyze geometry faster or use a packed vertex format or color normals

/// @param _vertex_buffer
/// @param _vertex_format
/// @param _zfail
/// @param _shadow_volume_vertex_format
function create_shadow_volume_buffer(_vertex_buffer,_vertex_format,_shadow_volume_vertex_format,_zfail)
{
	var _info = vertex_format_get_info(_vertex_format); //get vertex format information
	var _vertex_size = _info[$ "stride"]; //get vertex size from vertex format info
	var _triangle_size = _vertex_size*3; //calculate triangle size from vertex size (A TRIANGLE HAS 3 CORNERS, DONT BE TOO SHOOK'D)
	var _buffer_vertex_buffer = buffer_create_from_vertex_buffer(_vertex_buffer, buffer_fixed, 1); //extract vertex buffer data to a regular buffer to process
	var _buffer_size = buffer_get_size(_buffer_vertex_buffer); //size of vertex buffer
	var _buffer_shadows_vertex_buffer = buffer_create(_buffer_size, buffer_grow, 1); //create a grow buffer with initial size estimated as geometry buffer size
	var _num_triangles = _buffer_size/_triangle_size; //number of triangles in vertex buffer

	var _num_edges = 0; //total number of silhouette-forming edges in shadow volume buffer
	var _num_useless_edges = 0; //total number of non-silhouette-forming edges in shadow volume buffer
	var _num_cap_triangles = 0; //total number of triangles of original geometry added for depth-fail caps
	var _struct_edge_graph = {}; //edge graph
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
	
		if(_zfail) //only duplicate geometry to act as light/dark caps in zfail buffer
		{
			//write triangle into shadow volume buffer
			_num_cap_triangles++;
			//Triangle 1
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xA);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yA);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zA);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxA);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyA);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzA);
		
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xC);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yC);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zC);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxC);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyC);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzC);
		
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_xB);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_yB);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_zB);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nxB);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nyB);
			buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_nzB);
		}
		
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

						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A); 
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXA);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYA);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZA);
            
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A); 
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
								
						//Triangle 2
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y2A); 
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z2A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
								
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x1A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y1A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z1A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYB);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZB);
								
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_x1A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_y1A); 
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_z1A);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normXA);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normYA);
						buffer_write(_buffer_shadows_vertex_buffer,buffer_f32,_normZA);
								
						variable_struct_remove(_struct_edge_graph, _hash);
					}
				}
			}
		}
	}
	
	show_debug_message($"num silhouette edges: {_num_edges}");
	show_debug_message($"num coplanar/non-silhouette edges removed: {_num_useless_edges}");

	//resize shadow volume buffer
	var _shadow_volume_format_info = vertex_format_get_info(_shadow_volume_vertex_format);
	var _shadow_volume_vertex_size = _shadow_volume_format_info[$ "stride"];
	buffer_resize(_buffer_shadows_vertex_buffer,_shadow_volume_vertex_size*(3*2*_num_edges + 3*_num_cap_triangles)); //1 quad (2 triangles / 6 vertices) for each silhouette edge. If zfail buffer, 3 vertices per duplicated geometry triangle

	return vertex_create_buffer_from_buffer(_buffer_shadows_vertex_buffer, _shadow_volume_vertex_format);

	
}