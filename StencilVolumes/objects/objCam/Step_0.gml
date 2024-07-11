//advance time
global.time += 0.25;

//Set camera
switch(camera_type)
{
	case camera_types.orbit:
	{
		xfrom = (TILES_X/2)*BLOCK_SIZE + rad*dsin(phase);
		yfrom = (TILES_Y/2)*BLOCK_SIZE + rad*dcos(phase);
		//look towards center
		xto = BLOCK_SIZE*(TILES_X/2);
		yto = BLOCK_SIZE*(TILES_Y/2);
		zto = BLOCK_SIZE/2;
		break;
	}
	
	case camera_types.POV:
	{
		var camera_distance = 160;

		xfrom = Player.x;
		yfrom = Player.y;
		zfrom = Player.z + 64;
		xto = xfrom - camera_distance * dcos(Player.look_dir) * dcos(Player.look_pitch);
		yto = yfrom + camera_distance * dsin(Player.look_dir) * dcos(Player.look_pitch);
		zto = zfrom + camera_distance * dsin(Player.look_pitch);
		break;
	}
}


cameraMat = matrix_build_lookat(xfrom, yfrom, zfrom, xto, yto, zto, 0, 0, 1);
cameraProjMat = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 32000);
cameraProjMatBias = matrix_build_projection_perspective_fov(-60, -window_get_width() / window_get_height(), 1, 30000); //biased projection matrix (to remedy z-fighting with z-fail shadow volume geometry with model geometry)

if(mouse_check_button(mb_left))
{
	phase -= 1;	
}

if(mouse_check_button(mb_right))
{
	phase += 1;	
}

if(mouse_wheel_up())
{
	rad -= 5;
}

if(mouse_wheel_down())
{
	rad += 5;
}

if(keyboard_check(ord("W")))
{
	zfrom += 1;	
}

if(keyboard_check(ord("S")))
{
	zfrom -= 1;	
}

if (keyboard_check(ord("D"))){
	y += 10;	
}
if (keyboard_check(vk_space)){
	z -= 10;	
}
if (keyboard_check(vk_control)){
	z += 10;	
}
if (keyboard_check(ord("A"))){
	y -= 10;	
}
if (keyboard_check(ord("W"))){
	x += 10;	
}
if (keyboard_check(ord("S"))){
	x -= 10;	
}

if keyboard_check(ord("J")){
	lightArray[0] -= 0.1;	
}
if keyboard_check(ord("K")){
	lightArray[0] += 0.1;	
}
if keyboard_check(ord("U")){
	lightArray[1] -= 0.1;	
}
if keyboard_check(ord("I")){
	lightArray[1] += 0.1;	
}
if keyboard_check(ord("N")){
	lightArray[2] -= 0.1;	
}
if keyboard_check(ord("M")){
	lightArray[2] += 0.1;	
}

//if (mouseLock){
//	window_mouse_set(clamp(window_mouse_get_x(), 0, window_get_width()), clamp(window_mouse_get_y(), 0, window_get_height()));
//	window_mouse_set(window_get_width()/2, window_get_height()/2);
//}

//if (mouseLock){
//		moveDir -= (window_mouse_get_x()-window_get_width()/2)/6;
//        if moveDir < 0{
//            moveDir += 360;}
//        if moveDir > 360{
//            moveDir -= 360;}
            
//        movePitch += (window_mouse_get_y()-window_get_height()/2)/6;
//}