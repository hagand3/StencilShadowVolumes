function load_obj(argument0, argument1) {

	// Open the file
	var filename = argument0;
	var mtlname = argument1;

	var obj_file = file_text_open_read(filename);
	var mtl_file = file_text_open_read(mtlname);

	var mtl_name = "None";
	var active_mtl = "None";

	// Create ds_maps to link the color/alpha/other attributes to the material name

	var mtl_alpha = ds_map_create();
	var mtl_color = ds_map_create();

	// Set the default attributes

	ds_map_add(mtl_alpha, "None", 1);
	ds_map_add(mtl_color, "None", c_white);

	// For each line in the mtl file

	while(not file_text_eof(mtl_file)){
		var line = file_text_read_string(mtl_file);
		file_text_readln(mtl_file);
		// Split each line around the space character
		var terms, index;
		index = 0;
		terms[0] = "";
		terms[string_count(line, " ")] = "";
		for (var i = 1; i <= string_length(line); i++){
			if (string_char_at(line, i) == " "){
				index++;
				terms[index] = "";
			} else {
				terms[index] = terms[index]+string_char_at(line, i);
			}
		}
		switch(terms[0]){
			case "newmtl":
				// Set the material name
				mtl_name = terms[1];
				break;
			case "Kd":
				// Diffuse color (the color we're concerned with)
				var red = real(terms[1])*255;
				var green = real(terms[2])*255;
				var blue = real(terms[3])*255;
				var color = make_color_rgb(red, green, blue);
				ds_map_set(mtl_color, mtl_name, color);
				break;
			case "d":
				// "dissolved" (alpha)
				var alpha = real(terms[1]);
				ds_map_set(mtl_alpha, mtl_name, alpha);
				break;
			default:
				// There are way more available attributes in mtl files, but we're only concerned with these three (two)
				break;
		}
	}

	// Create the vertex buffer
	var model = vertex_create_buffer();
	vertex_begin(model, objCam.vertex_format);

	// Create the lists of position/normal/texture data
	var vertex_x = ds_list_create();
	var vertex_y = ds_list_create();
	var vertex_z = ds_list_create();

	var vertex_nx = ds_list_create();
	var vertex_ny = ds_list_create();
	var vertex_nz = ds_list_create();

	var vertex_xtex = ds_list_create();
	var vertex_ytex = ds_list_create();

	// Read each line in the file
	while(not file_text_eof(obj_file)){
		var line = file_text_read_string(obj_file);
		file_text_readln(obj_file);
		// Split each line around the space character
		var terms, index;
		index = 0;
		terms = array_create(string_count(line, " ") + 1, "");
		for (var i = 1; i <= string_length(line); i++){
			if (string_char_at(line, i) == " "){
				index++;
				terms[index] = "";
			} else {
				terms[index] += string_char_at(line, i);
			}
		}
		switch(terms[0]){
			// Add the vertex x, y an z position to their respective lists
			case "v":
				ds_list_add(vertex_x, real(terms[1]));
				ds_list_add(vertex_y, real(terms[2]));
				ds_list_add(vertex_z, real(terms[3]));
				break;
			// Add the vertex x and y texture position (or "u" and "v") to their respective lists
			case "vt":
				ds_list_add(vertex_xtex, real(terms[1]));
				ds_list_add(vertex_ytex, real(terms[2]));
				break;
			// Add the vertex normal's x, y and z components to their respective lists
			case "vn":
				ds_list_add(vertex_nx, real(terms[1]));
				ds_list_add(vertex_ny, real(terms[2]));
				ds_list_add(vertex_nz, real(terms[3]));
				break;
			case "f":
				// Split each term around the slash character
				for (var n = 1; n <= 3; n++){
					var data, index;
					index = 0;
					data = array_create(string_count(terms[n], "/") + 1, "");
					for (var i = 1; i <= string_length(terms[n]); i++){
						if (string_char_at(terms[n], i) == "/"){
							index++;
							data[index] = "";
						} else {
							data[index] += string_char_at(terms[n], i);
						}
					}
					// Look up the x, y, z, normal x, y, z and texture x, y in the already-created lists
					var xx = ds_list_find_value(vertex_x, real(data[0]) - 1);
					var yy = ds_list_find_value(vertex_y, real(data[0]) - 1);
					var zz = ds_list_find_value(vertex_z, real(data[0]) - 1);
					var xtex = ds_list_find_value(vertex_xtex, real(data[1]) - 1);
					var ytex = ds_list_find_value(vertex_ytex, real(data[1]) - 1);
					var nx = ds_list_find_value(vertex_nx, real(data[2]) - 1);
					var ny = ds_list_find_value(vertex_ny, real(data[2]) - 1);
					var nz = ds_list_find_value(vertex_nz, real(data[2]) - 1);
					// If the material exists in the materials map(s), set the vertex's color and alpha
					// (and other attributes, if you want to use them) based on the material

					
					var color = c_white;
					var alpha = 1;
					if (ds_map_exists(mtl_color, active_mtl)){
						color = ds_map_find_value(mtl_color, active_mtl);
					}
					if (ds_map_exists(mtl_alpha, active_mtl)){
						alpha = ds_map_find_value(mtl_alpha, active_mtl);
					}
				
					// Optional: swap the y and z positions (useful if you used the default Blender export settings)
					var t = yy;
					yy = zz;
					zz = t;
					
					var tN = ny;
					ny = nz;
					nz = tN; //flip normal
					
					array_push(objCam.vertexArray, xx, yy, zz);
					array_push(objCam.normalArray, nx, ny, nz); 
				
					// Add the data to the vertex buffers
					vertex_position_3d(model, xx, yy, zz);
					vertex_normal(model, nx, ny, nz);
					vertex_color(model, color, alpha);
					vertex_texcoord(model, xtex, ytex);
				}
				break;
			case "usemtl":
				active_mtl = terms[1];
				break;
			default:
				// There are a few other things you can find in an obj file that I haven't covered here (but may in the future)
				break;
		}
	}

	// End the vertex buffer, destroy the lists, close the text file and return the vertex buffer

	vertex_end(model);
	//vertex_freeze(model);

	ds_list_destroy(vertex_x);
	ds_list_destroy(vertex_y);
	ds_list_destroy(vertex_z);
	ds_list_destroy(vertex_nx);
	ds_list_destroy(vertex_ny);
	ds_list_destroy(vertex_nz);
	ds_list_destroy(vertex_xtex);
	ds_list_destroy(vertex_ytex);

	ds_map_destroy(mtl_alpha);
	ds_map_destroy(mtl_color);

	file_text_close(obj_file);
	file_text_close(mtl_file);

	//objControl._buffer = model;
	
	return model;

}
	
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
	
function load_obj_mat(argument0, argument1) {

	// Open the file
	var filename = argument0;
	var mtlname = argument1;

	var obj_file = file_text_open_read(filename);
	var mtl_file = file_text_open_read(mtlname);

	var mtl_name = "None";
	var active_mtl = "None";

	// Create ds_maps to link the color/alpha/other attributes to the material name

	var mtl_alpha = ds_map_create();
	var mtl_color = ds_map_create();

	// Set the default attributes

	ds_map_add(mtl_alpha, "None", 1);
	ds_map_add(mtl_color, "None", c_white);

	// For each line in the mtl file

	while(not file_text_eof(mtl_file)){
		var line = file_text_read_string(mtl_file);
		file_text_readln(mtl_file);
		// Split each line around the space character
		var terms, index;
		index = 0;
		terms[0] = "";
		terms[string_count(line, " ")] = "";
		for (var i = 1; i <= string_length(line); i++){
			if (string_char_at(line, i) == " "){
				index++;
				terms[index] = "";
			} else {
				terms[index] = terms[index]+string_char_at(line, i);
			}
		}
		switch(terms[0]){
			case "newmtl":
				// Set the material name
				mtl_name = terms[1];
				break;
			case "Kd":
				// Diffuse color (the color we're concerned with)
				var red = real(terms[1])*255;
				var green = real(terms[2])*255;
				var blue = real(terms[3])*255;
				var color = make_color_rgb(red, green, blue);
				ds_map_set(mtl_color, mtl_name, color);
				break;
			case "d":
				// "dissolved" (alpha)
				var alpha = real(terms[1]);
				ds_map_set(mtl_alpha, mtl_name, alpha);
				break;
			default:
				// There are way more available attributes in mtl files, but we're only concerned with these three (two)
				break;
		}
	}

	// Create the vertex buffer
	//var model = vertex_create_buffer();
	//vertex_begin(model, objCam.vertex_format);

	// Create the lists of position/normal/texture data
	var vertex_x = ds_list_create();
	var vertex_y = ds_list_create();
	var vertex_z = ds_list_create();

	var vertex_nx = ds_list_create();
	var vertex_ny = ds_list_create();
	var vertex_nz = ds_list_create();

	var vertex_xtex = ds_list_create();
	var vertex_ytex = ds_list_create();

	// Read each line in the file
	while(not file_text_eof(obj_file)){
		var line = file_text_read_string(obj_file);
		file_text_readln(obj_file);
		// Split each line around the space character
		var terms, index;
		index = 0;
		terms = array_create(string_count(line, " ") + 1, "");
		for (var i = 1; i <= string_length(line); i++){
			if (string_char_at(line, i) == " "){
				index++;
				terms[index] = "";
			} else {
				terms[index] += string_char_at(line, i);
			}
		}
		switch(terms[0]){
			// Add the vertex x, y an z position to their respective lists
			case "v":
				ds_list_add(vertex_x, real(terms[1]));
				ds_list_add(vertex_y, real(terms[2]));
				ds_list_add(vertex_z, real(terms[3]));
				break;
			// Add the vertex x and y texture position (or "u" and "v") to their respective lists
			case "vt":
				ds_list_add(vertex_xtex, real(terms[1]));
				ds_list_add(vertex_ytex, real(terms[2]));
				break;
			// Add the vertex normal's x, y and z components to their respective lists
			case "vn":
				ds_list_add(vertex_nx, real(terms[1]));
				ds_list_add(vertex_ny, real(terms[2]));
				ds_list_add(vertex_nz, real(terms[3]));
				break;
			case "usemtl":
				active_mtl = terms[1];
				modIndex++;
				modelArray[modIndex] = vertex_create_buffer();
				materialArray[modIndex] = active_mtl;
				vertex_begin(modelArray[modIndex], objCam.vertex_format);
					//vertex_freeze(modelArray[modIndex]);
				break;
			case "f":
				// Split each term around the slash character
				for (var n = 1; n <= 3; n++){
					var data, index;
					index = 0;
					data = array_create(string_count(terms[n], "/") + 1, "");
					for (var i = 1; i <= string_length(terms[n]); i++){
						if (string_char_at(terms[n], i) == "/"){
							index++;
							data[index] = "";
						} else {
							data[index] += string_char_at(terms[n], i);
						}
					}
					// Look up the x, y, z, normal x, y, z and texture x, y in the already-created lists
					var xx = ds_list_find_value(vertex_x, real(data[0]) - 1);
					var yy = ds_list_find_value(vertex_y, real(data[0]) - 1);
					var zz = ds_list_find_value(vertex_z, real(data[0]) - 1);
					var xtex = ds_list_find_value(vertex_xtex, real(data[1]) - 1);
					var ytex = ds_list_find_value(vertex_ytex, real(data[1]) - 1);
					var nx = ds_list_find_value(vertex_nx, real(data[2]) - 1);
					var ny = ds_list_find_value(vertex_ny, real(data[2]) - 1);
					var nz = ds_list_find_value(vertex_nz, real(data[2]) - 1);
					// If the material exists in the materials map(s), set the vertex's color and alpha
					// (and other attributes, if you want to use them) based on the material

					
					var color = c_white;
					var alpha = 1;
					if (ds_map_exists(mtl_color, active_mtl)){
						color = ds_map_find_value(mtl_color, active_mtl);
					}
					if (ds_map_exists(mtl_alpha, active_mtl)){
						alpha = ds_map_find_value(mtl_alpha, active_mtl);
					}
				
					// Optional: swap the y and z positions (useful if you used the default Blender export settings)
					var t = yy;
					yy = zz;
					zz = t;
					
					var tN = ny;
					ny = nz;
					nz = tN;
					
					array_push(objCam.vertexArray, xx, yy, zz);
					array_push(objCam.normalArray, nx, ny, nz);
				
					// Add the data to the vertex buffers
					vertex_position_3d(modelArray[modIndex], xx, yy, zz);
					vertex_normal(modelArray[modIndex], nx, ny, nz);
					vertex_color(modelArray[modIndex], color, alpha);
					vertex_texcoord(modelArray[modIndex], xtex, ytex);
				}
				break;
					//vertex_end(modelArray[modIndex]);
					//vertex_freeze(modelArray[modIndex]);
			default:
				// There are a few other things you can find in an obj file that I haven't covered here (but may in the future)
				break;
		}
	}

	// End the vertex buffer, destroy the lists, close the text file and return the vertex buffer

	for (var p = 0; p < array_length(modelArray); p++){
		vertex_end(modelArray[p]);
		//vertex_freeze(modelArray[p]);
	}

	ds_list_destroy(vertex_x);
	ds_list_destroy(vertex_y);
	ds_list_destroy(vertex_z);
	ds_list_destroy(vertex_nx);
	ds_list_destroy(vertex_ny);
	ds_list_destroy(vertex_nz);
	ds_list_destroy(vertex_xtex);
	ds_list_destroy(vertex_ytex);

	ds_map_destroy(mtl_alpha);
	ds_map_destroy(mtl_color);

	file_text_close(obj_file);
	file_text_close(mtl_file);

	//objControl._buffer = model;
	
	return modelArray;


}