extern vec2 screen_size;
extern float time;
extern float noise_amount = 0.1;
extern float scanline_intensity = 0.2;
extern float color_depth = 32.0;
extern float pixel_size = 2.0;

// Pseudo-random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Pixelation
    vec2 pixel_coords = floor(screen_coords / pixel_size) * pixel_size;
    vec2 normalized_coords = pixel_coords / screen_size;
    
    // Add slight jitter (reduced movement)
    vec2 jitter = vec2(
        rand(vec2(time * 0.5, normalized_coords.y)) * 2.0 - 1.0,
        rand(vec2(normalized_coords.x, time * 0.5)) * 2.0 - 1.0
    ) * noise_amount;
    
    normalized_coords += jitter;
    
    // Sample the texture
    vec4 pixel = Texel(tex, normalized_coords);
    
    // Color quantization
    pixel.rgb = floor(pixel.rgb * color_depth) / color_depth;
    
    // Scanlines (reduced frequency and softened)
    float scanline = sin(screen_coords.y * 0.25 + time * 5.0) * 0.5 + 0.5;
    pixel.rgb *= 1.0 - (scanline * scanline_intensity);
    
    // Add slight color shift (reduced amount)
    float shift = sin(time * 1.0) * 0.005;
    pixel.r += shift;
    pixel.b -= shift;
    
    // Add slight vertical color banding (reduced amount)
    float band = sin(screen_coords.y * 0.05 + time) * 0.01;
    pixel.rgb += vec3(band);
    
    // Clamp colors
    pixel.rgb = clamp(pixel.rgb, 0.0, 1.0);
    
    return pixel * color;
}
