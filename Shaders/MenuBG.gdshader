shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float x = sin(UV.x);
	float y = cos(UV.y);
	vec4 effect = vec4(
		cos(1512. * (x - y)) + (.133 * cos(321. * sin(x - y + 2.))),
		sin(1673. * (x - y * 0.125)),
		sin(1394. * (x + y * 0.4)),
	1);
	col *= effect * 1.667;
	COLOR = col;
}
