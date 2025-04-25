/*        Cinematic Post Processing for Godot v1.0       */
/*                Developed by Hamid.Memar               */
/*                      License : MIT                    */

shader_type canvas_item;

// Render Layer
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Parameters
uniform float grain_strength = 0.04;
uniform float grain_scale = 1.2;
uniform float aberration_strength = -0.012;
uniform vec2 ripplePos = vec2(0.5, 0.5);
uniform float rippleRadius = -1.0;
uniform float rippleThickness = 0.2;
uniform float rippleDisturbance = 0.0;
uniform float rippleFalloff = 4.0;
uniform bool glitch_enabled = false;
uniform float glitch_blend = 0.5;
uniform float glitch_effect_power = 0.3;
uniform float glitch_rgb_shifting = 0.045;
uniform float glitch_pixel_shifting = 0.7;
uniform vec2 glitch_pixel_size = vec2(0.09, 0.09);

// Utilities
float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
}
vec3 grain_noise(vec2 uv)
{
    float grain_r = rand(uv * grain_scale + TIME * 0.3);
    float grain_g = rand(uv * grain_scale + TIME * 0.5 + vec2(10.0, 5.0));
    float grain_b = rand(uv * grain_scale + TIME * 0.7 + vec2(-3.0, 2.0));
    return vec3(grain_r, grain_g, grain_b);
}
vec2 ripple_UV(vec2 uv)
{
	vec2 rippleUV = uv;
	vec2 dir = uv - ripplePos;
	float dist = length(dir);
	float ring = dist - rippleRadius;
	float fade = 1.0 - smoothstep(0.0, rippleThickness, abs(ring));
	fade *= pow(1.0 - smoothstep(0.0, 1.0, dist), rippleFalloff);
	float wave = sin(ring * 30.0 - TIME * 10.0);
	rippleUV += normalize(dir) * wave * rippleDisturbance * fade;
	return rippleUV;
}
vec3 glitch(vec2 uv)
{
	vec2 block_uv = floor(uv / glitch_pixel_size) * glitch_pixel_size;
	float time_shift = floor(TIME * 20.0);
	float seed = rand(vec2(block_uv.x * 13.37, block_uv.y * 91.91) + time_shift);
	float band = step(glitch_pixel_shifting, fract(seed * 10.0)) * glitch_effect_power;
	float rgb_shift = glitch_rgb_shifting * (rand(block_uv + time_shift) - 0.5);
	vec2 glitch_uv = uv + vec2(band, 0.0);
	float r = texture(screen_texture, glitch_uv + vec2(-rgb_shift, 0.0)).r;
	float g = texture(screen_texture, glitch_uv).g;
	float b = texture(screen_texture, glitch_uv + vec2(rgb_shift, 0.0)).b;
	return vec3(r, g, b);
}

// Pixel Render
void fragment()
{
	// Ripple Effect
	vec2 rippleUV = ripple_UV(SCREEN_UV);

	// Chromatic Aberration
    vec2 center = vec2(0.5);
    vec2 dir = normalize(rippleUV - center);
    float dist = length(rippleUV - center);
    float strength = aberration_strength * pow(dist, 1.5);
    float r = (
        texture(screen_texture, rippleUV + dir * strength * 1.0).r +
        texture(screen_texture, rippleUV + dir * strength * 0.5).r) * 0.5;
    float g = (
        texture(screen_texture, rippleUV).g +
        texture(screen_texture, rippleUV + dir * strength * 0.2).g) * 0.5;
    float b = (
        texture(screen_texture, rippleUV - dir * strength * 0.5).b +
        texture(screen_texture, rippleUV - dir * strength * 1.0).b) * 0.5;
    vec3 color = vec3(r, g, b);

	// Glitch Effect
	if (glitch_enabled) color = mix(color, glitch(rippleUV), glitch_blend);

    // Film Grain
    vec3 noise = grain_noise(rippleUV);
    color += (noise - 0.5) * 2.0 * grain_strength;

	// Final Color
    COLOR = vec4(color, 1.0);
}