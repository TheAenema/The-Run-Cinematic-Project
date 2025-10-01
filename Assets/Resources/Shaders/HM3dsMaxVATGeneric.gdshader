/*    3ds Max Vertex Animation Texture for Godot v1.0    */
/*                Developed by Hamid.Memar               */
/*         License : Creative Commons (CC) BY 4.0        */

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform float rim : hint_range(0.0, 1.0, 0.01);
uniform float rim_tint : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_rim : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

uniform vec4 backlight : source_color;
uniform sampler2D texture_backlight : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;

// VAT Properties
uniform sampler2D vat_positions_texture;
uniform sampler2D vat_normals_texture;
uniform vec3 vat_min;
uniform vec3 vat_max;
uniform bool fix_axis = true;
uniform float vat_weight = 1.0;
uniform float animate_speed = 30.0;
uniform float animate_offset = 0.0;
uniform ivec2 flipbook_dimensions = ivec2(2, 2);

// Animator
vec2 animateUV(vec2 uv, ivec2 size, float index)
{
    index = mod(index, float(size.x * size.y));
    vec2 frame_size = vec2(1.0) / vec2(size);
    vec2 frame = fract(uv) * frame_size;
    frame.x += mod(index, float(size.x)) * frame_size.x;
    frame.y += floor(index / float(size.x)) * frame_size.y;
    return frame;
}

// Vertex Render
void vertex() {

    float frame_float = TIME * animate_speed + animate_offset;
    float frame_index = floor(frame_float);
    float frame_frac = fract(frame_float);

    vec2 uv_current = animateUV(UV2, flipbook_dimensions, frame_index);
    vec2 uv_next = animateUV(UV2, flipbook_dimensions, frame_index + 1.0);

    vec3 vat_current = texture(vat_positions_texture, uv_current).rgb;
    vec3 vat_next = texture(vat_positions_texture, uv_next).rgb;

    vec3 normal_current = texture(vat_normals_texture, uv_current).rgb * 2.0 - 1.0;
    vec3 normal_next = texture(vat_normals_texture, uv_next).rgb * 2.0 - 1.0;

    vec3 vat_data = mix(vat_current, vat_next, frame_frac);
    vec3 normal = normalize(mix(normal_current, normal_next, frame_frac));

    vec3 position = mix(vat_min, vat_max, vat_data);

    vec3 computedVertex = vec3(0);
    vec3 computedNormal = vec3(0);
    if (fix_axis) {
        mat3 rotateX90 = mat3(
            vec3(1.0, 0.0, 0.0),
            vec3(0.0, 0.0, 1.0),
            vec3(0.0, -1.0, 0.0)
        );
        computedVertex = rotateX90 * position;
        computedNormal = rotateX90 * normal;
    } else {
        computedVertex = position;
        computedNormal = normal;
    }

    VERTEX = mix(VERTEX, computedVertex, vat_weight);
    NORMAL = mix(NORMAL, computedNormal, vat_weight);
}

// Pixel Render
void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	// Rim: Enabled
	vec2 rim_tex = texture(texture_rim, base_uv).xy;
	RIM = rim * rim_tex.x;
	RIM_TINT = rim_tint * rim_tex.y;

	// Ambient Occlusion: Enabled
	AO = dot(texture(texture_ambient_occlusion, base_uv), ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;

	// Backlight: Enabled
	vec3 backlight_tex = texture(texture_backlight, base_uv).rgb;
	BACKLIGHT = (backlight.rgb + backlight_tex);
}
