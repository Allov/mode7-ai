uniform vec2 cameraPos;
uniform float cameraAngle;
uniform float cameraHeight;  // This will now receive the bobbing height
uniform float horizonLine;
uniform vec2 textureDimensions;
uniform float maxDistance;
uniform vec3 fogColor;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Skip shader for pixels above horizon - sky is drawn separately
    if (screen_coords.y < horizonLine) {
        discard;  // Let the sky texture show through
    }
    
    // Use dynamic camera height for perspective calculation
    float distance = (cameraHeight * (love_ScreenSize.y - horizonLine)) 
                    / (screen_coords.y - horizonLine);
    
    // Calculate world position
    vec2 worldPos;
    float aspectRatio = love_ScreenSize.x / love_ScreenSize.y;
    // Convert screen space to world space
    worldPos.x = (screen_coords.x - love_ScreenSize.x * 0.5) * distance / (love_ScreenSize.y * 0.5);
    worldPos.y = distance;
    
    // Rotate world position
    float cosA = cos(-cameraAngle);  // Note: Positive angle
    float sinA = sin(-cameraAngle);
    vec2 rotated = vec2(
        worldPos.x * cosA - worldPos.y * sinA,
        worldPos.x * sinA + worldPos.y * cosA
    );
    
    // Add camera position
    rotated += cameraPos;
    
    // Sample texture with wrapping
    vec2 texCoord = rotated / textureDimensions;
    vec4 texColor = Texel(tex, mod(texCoord, 1.0)) * color;
    
    // Apply fog
    float fogStart = maxDistance * 0.6;
    float fogFactor = smoothstep(fogStart, maxDistance, distance);
    
    return mix(texColor, vec4(fogColor, 1.0), fogFactor);
}




