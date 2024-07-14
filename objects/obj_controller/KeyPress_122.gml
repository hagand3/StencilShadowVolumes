/// @description Show/Hide GUI

show_GUI = !show_GUI;

if(DEBUG_OVERLAY)
{
	if(show_GUI)
	{
		show_debug_overlay(true,true,1);
	}	else
	{
		show_debug_overlay(false,true,1);
	}
}