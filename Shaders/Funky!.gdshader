shader_type canvas_item;

const vec4 r = vec4(1, 0, 0, 1);
const vec4 g = vec4(0, 1, 0, 1);
const vec4 b = vec4(0, 0, 1, 1);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float hue = fract(sin(UV.x) + cos(UV.y) + 0.4);
	vec4 new = vec4(0, 0, 0, 0);
	if(hue < 0.33)
		new = mix(r, g, hue * 3.);
	else if(hue > 0.33 && hue < 0.67)
		new = mix(g, b, (hue - 0.33) * 3.);
	else
		new = mix(b, r, (hue - 0.67) * 3.);
	COLOR = col * new;
}
