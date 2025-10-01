/*      Display Screen Animator for Godot v1.0      */
/*            Developed by Hamid.Memar              */
/*                 License : MIT                    */

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);
varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform bool animate = false;
uniform float animate_speed = 30.0;
uniform float animate_offset = 0.0;
uniform ivec2 flipbook_dimensions = ivec2(2, 2);

// Helpers
vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

// Animator
vec2 animateUV(vec2 uv, ivec2 size, float progress)
{
        progress = floor(mod(progress, float(size.x * size.y)));
        vec2 frame_size = vec2(1.0) / vec2(size);
        vec2 frame = fract(uv) * frame_size;
        frame.x += (mod(progress, float(size.x))) * frame_size.x;
        frame.y += float(int(progress) / size.x) * frame_size.y;
        return frame;
}

// Vertex Render
void vertex() {
	vec3 normal = NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);

	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

// Pixel Render
void fragment() {
	vec2 displayUV = vec2(1.0);
	if (animate) displayUV = animateUV(UV, flipbook_dimensions, TIME * animate_speed + animate_offset);
	else displayUV = UV;
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	NORMAL_MAP = triplanar_texture(texture_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	vec3 emission_tex = texture(texture_emission, displayUV).rgb;
	EMISSION = (emission.rgb + emission_tex) * emission_energy;
}
