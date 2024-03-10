shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

uniform vec3 base_color: source_color;
uniform vec3 light_color: source_color;
uniform vec3 shadow_color: source_color;

uniform bool rainbow;

vec3 float_to_color(float x) {
	x += TIME/4.0;
	x = fract(x);
	float step_size = 1.0/6.0;
	if (x < step_size * 1.0) {
		return mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0), x * 6.0);
	}
	else if (x < step_size * 2.0) {
		return mix(vec3(1.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0), (x - step_size) * 6.0);
	}
	else if (x < step_size * 3.0) {
		return mix(vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 1.0), (x - step_size*2.0) * 6.0);
	}
	else if (x < step_size * 4.0) {
		return mix(vec3(0.0, 1.0, 1.0), vec3(0.0, 0.0, 1.0), (x - step_size*3.0) * 6.0);
	}
	else if (x < step_size * 5.0) {
		return mix(vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 1.0), (x - step_size*4.0) * 6.0);
	}
	else if (x < step_size * 6.0) {
		return mix(vec3(1.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), (x - step_size*5.0) * 6.0);
	}
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float dot_prod = (dot(NORMAL, LIGHT) + 1.0) / 2.0;
		if (rainbow) {
			DIFFUSE_LIGHT = float_to_color(dot_prod);
		}
		else if (dot_prod > 0.5) {
			DIFFUSE_LIGHT = mix(base_color, light_color, (dot_prod - 0.5)*2.0);
		}
		else {
			DIFFUSE_LIGHT = mix(shadow_color, base_color, dot_prod*2.0);
		}
	}
}
