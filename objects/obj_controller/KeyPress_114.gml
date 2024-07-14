/// @description Toggle Shadow Volume Technique (ZPass / ZFail)
shadow_volumes_render_technique = shadow_volumes_render_technique == shadow_volumes_render_techniques.depth_pass ? shadow_volumes_render_techniques.depth_fail : shadow_volumes_render_techniques.depth_pass;

switch(shadow_volumes_render_technique)
{
	case shadow_volumes_render_techniques.depth_fail:
	{
		var _shadow_vbuff = zfail_shadow_volume_vertex_buffer; //default zfail	
		break;
	}
	
	case shadow_volumes_render_techniques.depth_pass:
	{
		var _shadow_vbuff = zpass_shadow_volume_vertex_buffer; //zpass
		break;
	}
}

with(obj_block)
{
	shadow_vbuff = _shadow_vbuff; //set shadow vbuff to either zpass or zfail buffer
}