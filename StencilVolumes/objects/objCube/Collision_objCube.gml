/// @description Insert description here
// You can write your code in this editor
if(!collision_this_frame and !other.collision_this_frame)
{
	var _phi = point_direction(x,y,other.x,other.y);
	var _x_spd_r1 = spd*dcos(dir - _phi);
	var _y_spd_r1 = spd*dsin(dir - _phi);
	var _x_spd_r2 = other.spd*dcos(other.dir - _phi);
	var _y_spd_r2 = other.spd*dsin(other.dir - _phi);
	other.spd_x = 
	
	
	other.collision_this_frame = true;
	collision_this_frame = true;
}