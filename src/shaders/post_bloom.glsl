extern vec2 screen_size;
extern float threshold = 0.4;     // Lower threshold
extern float intensity = 1.5;     // Higher intensity
extern float blur_size = 8.0;     // Larger blur
extern int pass;                  // 0 = brightness/blur, 1 = combine

// Increased number of samples for smoother blur
const float weights[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 tex_offset = (1.0 / screen_size) * blur_size;
    vec4 result = vec4(0.0);

    if (pass == 0) {  // Brightness extraction and horizontal blur
        // Sample center pixel
        vec4 pixel = Texel(tex, texture_coords);
        
        // More aggressive brightness extraction
        float brightness = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
        float multiplier = max(1.0, brightness / threshold);
        vec4 brightColor = pixel * multiplier * step(threshold, brightness);
        
        // Horizontal blur with higher weights
        result = brightColor * weights[0] * 1.5;  // Increased center weight
        for (int i = 1; i < 5; i++) {
            result += Texel(tex, texture_coords + vec2(tex_offset.x * i, 0.0)) * weights[i] * 1.5;
            result += Texel(tex, texture_coords - vec2(tex_offset.x * i, 0.0)) * weights[i] * 1.5;
        }
    }
    else if (pass == 1) {  // Vertical blur and intensity
        // Vertical blur with higher weights
        vec4 blurred = Texel(tex, texture_coords) * weights[0] * 1.5;
        for (int i = 1; i < 5; i++) {
            blurred += Texel(tex, texture_coords + vec2(0.0, tex_offset.y * i)) * weights[i] * 1.5;
            blurred += Texel(tex, texture_coords - vec2(0.0, tex_offset.y * i)) * weights[i] * 1.5;
        }
        
        // Apply increased intensity
        result = blurred * intensity;
        
        // Add slight color shift to make bloom more visible
        result.rgb += vec3(0.1, 0.05, 0.0) * result.a;
    }

    return result * color;
}


