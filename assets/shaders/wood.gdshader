shader_type spatial;
render_mode skip_vertex_transform;

uniform sampler2D main_texture: hint_default_white;
uniform sampler2D normal_texture;
uniform sampler2D rough_texture: hint_roughness_gray;

uniform float texture_scale;
uniform float layer_offset;
uniform vec2 uv_offset;
uniform float uv_rotation;

uniform vec3 hole_location;

uniform uint quality_level;

void vertex() {
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (any((notEqual(hole_location, vec3(0, 0, 0))))) {
		float dist_from_hole = distance(VERTEX, hole_location);
		VERTEX.y -= 5.0 / pow(dist_from_hole, 3.0);	
	}
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

void fragment() {
	vec3 WORLD_VERTEX = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 WORLD_UV = WORLD_VERTEX.xz/texture_scale + vec2(WORLD_VERTEX.y * layer_offset) + uv_offset;
	
	float sin_rotation = sin(uv_rotation);
	float cos_rotation = cos(uv_rotation);
	WORLD_UV = vec2(
		cos_rotation * WORLD_UV.x - sin_rotation * WORLD_UV.y,
		sin_rotation * WORLD_UV.x + cos_rotation * WORLD_UV.y
	);
	
	ALBEDO = texture(main_texture, WORLD_UV).rgb * (WORLD_VERTEX.y+2.0)/4.0;
	
	if (quality_level >= 3u) {
		TANGENT = normalize(INV_VIEW_MATRIX * vec4(TANGENT, 1.0)).xyz;
		BINORMAL = normalize(INV_VIEW_MATRIX * vec4(BINORMAL, 1.0)).xyz;
		NORMAL_MAP = texture(normal_texture, WORLD_UV).rgb;
		
		ROUGHNESS = texture(rough_texture, WORLD_UV).r;
	}
}
