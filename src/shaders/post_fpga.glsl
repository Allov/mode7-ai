extern vec2 screen_size;
extern float time;
extern float noise_amount = 0.02;    // Subtle noise
extern float scanline_intensity = 0.1; // Soft scanlines
extern float color_depth = 32.0;     // Smoother color quantization
extern float pixel_size = 1.5;       // Slight pixelation

// Pseudo-random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Pixelation
    vec2 pixel_coords = floor(screen_coords / pixel_size) * pixel_size;
    vec2 normalized_coords = pixel_coords / screen_size;
    
    // Add very subtle jitter
    vec2 jitter = vec2(
        rand(vec2(time * 0.1, normalized_coords.y)) * 2.0 - 1.0,
        rand(vec2(normalized_coords.x, time * 0.1)) * 2.0 - 1.0
    ) * noise_amount;
    
    vec2 final_coords = texture_coords + jitter;
    
    // Sample the texture
    vec4 pixel = Texel(tex, final_coords);
    
    // Subtle color quantization
    pixel.rgb = floor(pixel.rgb * color_depth) / color_depth;
    
    // Soft scanlines
    float scanline = sin(screen_coords.y * 0.5 + time * 2.0) * 0.5 + 0.5;
    pixel.rgb *= 1.0 - (scanline * scanline_intensity);
    
    // Very subtle color shift
    float shift = sin(time * 0.5) * 0.002;
    pixel.r += shift;
    pixel.b -= shift;
    
    // Clamp colors
    pixel.rgb = clamp(pixel.rgb, 0.0, 1.0);
    
    return pixel * color;
}