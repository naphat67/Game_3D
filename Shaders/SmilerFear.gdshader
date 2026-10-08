shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float fear : hint_range(0.0, 1.0) = 0.0;
uniform float scare : hint_range(0.0, 1.0) = 0.0;
uniform float elapsed = 0.0;

float hash_noise(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float distortion = 0.0015 * fear + 0.009 * scare;
	vec2 tear = vec2(sin(uv.y * 110.0 + elapsed * 19.0) * distortion, 0.0);
	vec3 color = texture(screen_texture, uv + tear).rgb;
	vec3 red_channel = texture(screen_texture, uv + tear + vec2(distortion * 0.8, 0.0)).rgb;
	color.r = mix(color.r, red_channel.r, clamp(fear * 0.18 + scare * 0.62, 0.0, 0.8));
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(gray * 0.8, gray * 0.9, gray), fear * 0.22);
	float vignette = smoothstep(0.22, 0.78, distance(uv, vec2(0.5)));
	color *= 1.0 - vignette * (fear * 0.58 + scare * 0.32);
	float grain = hash_noise(floor(uv * vec2(760.0, 430.0) + floor(elapsed * 24.0))) - 0.5;
	color += grain * (fear * 0.12 + scare * 0.42);
	color = mix(color, vec3(0.88, 0.92, 1.0), scare * 0.16);
	COLOR = vec4(color, 1.0);
}
