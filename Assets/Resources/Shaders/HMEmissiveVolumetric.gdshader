
/*        Emissive Volumetric for Godot v1.0        */
/*            Developed by Hamid.Memar              */
/*      License : Creative Commons (CC) BY 4.0      */

// Shader Configuration
shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_opaque;

// Shader Parameters

uniform sampler2D volumetric_emission : source_color;
uniform vec3 absorption : source_color = vec3(1.0, 1.0, 1.0);
uniform float emission_power : hint_range(0.0, 10.0) = 1.0;
uniform float emission_color_shift : hint_range(0.0, 360.0) = 1.0;
uniform int billboard_mode = 0;
uniform bool billboard_keep_scale = true;
uniform bool animate = false;
uniform float animate_speed = 30.0;
uniform float animate_offset = 0.0;
uniform ivec2 flipbook_dimensions = ivec2(2, 2);

// Helpers
vec3 shiftColor(vec3 color, float shiftAngle)
{
	float Y = dot(color, vec3(0.299, 0.587, 0.114));
	float I = dot(color, vec3(0.596, -0.274, -0.322));
	float Q = dot(color, vec3(0.211, -0.523, 0.312));
	float rad = radians(shiftAngle);
	float cosA = cos(rad);
	float sinA = sin(rad);
	float newI = I * cosA - Q * sinA;
	float newQ = I * sinA + Q * cosA;
	return vec3(
		Y + 0.956 * newI + 0.621 * newQ,
		Y - 0.272 * newI - 0.647 * newQ,
		Y - 1.106 * newI + 1.703 * newQ
    	);
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
void vertex()
{

	// Y-Axis Billboard Only
	if (billboard_mode == 1)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	}

	// Full Billboard
	if (billboard_mode == 2)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	}

	// Keep Size When Billboarding
	if (billboard_mode != 0 && billboard_keep_scale)
	{
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

// Pixel Render
void fragment()
{
	// Calculate UV
	vec2 uv = vec2(1.0);
	vec2 uvNext = vec2(1.0);
	if (animate) {
		uv = animateUV(UV, flipbook_dimensions, TIME * animate_speed + animate_offset);
		uvNext = animateUV(UV, flipbook_dimensions, TIME * animate_speed + (animate_offset + 1.0));
	}
	else uv = UV;

	// Calculate Pixel Rendering
	ALBEDO = vec3(0);

	// Create Emission
	vec3 emission = texture(volumetric_emission, uv).rgb * emission_power * absorption;
	if (animate) {
		float frameBlend = fract(TIME * animate_speed + animate_offset);
		vec3 emissionNext = texture(volumetric_emission, uvNext).rgb * emission_power * absorption;
		emission = mix(emission, emissionNext, frameBlend);
	}
	EMISSION = shiftColor(emission, emission_color_shift);
	ALPHA = emission.r;
}