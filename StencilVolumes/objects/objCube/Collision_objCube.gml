/// @description Insert description here
// You can write your code in this editor
if(!collision_this_frame and !other.collision_this_frame and z < (other.z + BLOCK_SIZE) and (z + BLOCK_SIZE) > other.z)
{
	//var _phi = point_direction(x,y,other.x,other.y);
	var _phi = point_direction(other.x,other.y,x,y);
	//rotate coordinate system
	var _x_spd_r1 = spd*dcos(dir - _phi);
	var _y_spd_r1 = spd*dsin(dir - _phi);
	var _x_spd_r2 = other.spd*dcos(other.dir - _phi);
	var _y_spd_r2 = other.spd*dsin(other.dir - _phi);
	var _x_spd_fr1 = _x_spd_r2;
	var _x_spd_fr2 = _x_spd_r1;
	var _y_spd_fr1 = _y_spd_r1;
	var _y_spd_fr2 = _y_spd_r2;
	
	spd_x =	dcos(_phi)*_x_spd_fr1 + dcos(_phi + 90)*_y_spd_fr1;
	spd_y =	dsin(_phi)*_x_spd_fr1 + dsin(_phi + 90)*_y_spd_fr1;
	other.spd_x =	dcos(_phi)*_x_spd_fr2 + dcos(_phi + 90)*_y_spd_fr2;
	other.spd_y =	dsin(_phi)*_x_spd_fr2 + dsin(_phi + 90)*_y_spd_fr2;
	
	other.collision_this_frame = true;
	collision_this_frame = true;
}