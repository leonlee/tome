uniform float tick;

void main()
{
	// Change gl_ModelViewProjectionMatrix to a custom matrix once everything passes here
	gl_Position = gl_ModelViewProjectionMatrix * vec4(te4_position.x, te4_position.y, 0.0, 1.0);

	te4_uv = te4_texcoord;
	te4_fragcolor = te4_color;
}
