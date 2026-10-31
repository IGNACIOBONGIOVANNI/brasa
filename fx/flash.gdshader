shader_type canvas_item;
// Tiñe el dibujo hacia flash_color (golpes y telegraphs). flash_amount 0 = normal, 1 = color plano.

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
}
