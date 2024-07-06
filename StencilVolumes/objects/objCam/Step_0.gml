global.time += 0.25;
var _rad = 100;
xfrom = 50*BLOCK_SIZE + _rad*dsin(global.time);
yfrom = 50*BLOCK_SIZE + _rad*dcos(global.time);
zfrom = -80;

xto = xfrom + dcos(moveDir);
yto = yfrom - dsin(moveDir);
zto = zfrom + dsin(movePitch);

xto = BLOCK_SIZE*50;
yto = BLOCK_SIZE*50;
zto = -BLOCK_SIZE/2;

cameraMat = matrix_build_lookat(xfrom, yfrom, zfrom, xto, yto, zto, 0, 0, 1);
cameraProjMat = matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 10000);

if (mouse_check_button_pressed(mb_any))
{
    window_set_cursor(cr_none);
    mouseLock = true;
}
else if (keyboard_check_pressed(vk_escape))
{
    window_set_cursor(cr_default);
	mouseLock = false;
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

if (mouseLock){
	window_mouse_set(clamp(window_mouse_get_x(), 0, window_get_width()), clamp(window_mouse_get_y(), 0, window_get_height()));
	window_mouse_set(window_get_width()/2, window_get_height()/2);
}

if (mouseLock){
		moveDir -= (window_mouse_get_x()-window_get_width()/2)/6;
        if moveDir < 0{
            moveDir += 360;}
        if moveDir > 360{
            moveDir -= 360;}
            
        movePitch += (window_mouse_get_y()-window_get_height()/2)/6;
}