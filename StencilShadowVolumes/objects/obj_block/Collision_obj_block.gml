/// @description Cube Collision

//basic 2d collision
if(z < (other.z + BLOCK_SIZE) and (z + BLOCK_SIZE) > other.z)
{
	var _phi = point_direction(other.x,other.y,x,y); //get angle between colliding objects

	//rotate coordinate system
	var _x_spd_r1 = spd*dcos(dir - _phi);
	var _y_spd_r1 = spd*dsin(dir - _phi);
	var _x_spd_r2 = other.spd*dcos(other.dir - _phi);
	var _y_spd_r2 = other.spd*dsin(other.dir - _phi);
	var _x_spd_fr1 = _x_spd_r2;
	var _x_spd_fr2 = _x_spd_r1;
	var _y_spd_fr1 = _y_spd_r1;
	var _y_spd_fr2 = _y_spd_r2;
	
	//set new speeds according to elastic collision (mass assumed equal)
	spd_x		=	dcos(_phi)*_x_spd_fr1 + dcos(_phi + 90)*_y_spd_fr1;
	spd_y		=	dsin(_phi)*_x_spd_fr1 + dsin(_phi + 90)*_y_spd_fr1;
	other.spd_x =	dcos(_phi)*_x_spd_fr2 + dcos(_phi + 90)*_y_spd_fr2;
	other.spd_y =	dsin(_phi)*_x_spd_fr2 + dsin(_phi + 90)*_y_spd_fr2;

}