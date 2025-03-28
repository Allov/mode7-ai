uniform vec2 cameraPos;
uniform float cameraAngle;
uniform float cameraHeight;
uniform float horizonLine;
uniform vec2 textureDimensions;
uniform float maxDistance;  // Add this uniform for fog control
uniform vec3 fogColor;      // Add this for fog color

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Skip pixels above horizon
    if (screen_coords.y < horizonLine) {
        return vec4(fogColor, 1.0);  // Return fog color above horizon
    }
    
    // Calculate distance from camera to point on ground plane
    float distance = (cameraHeight * (love_ScreenSize.y - horizonLine)) 
                    / (screen_coords.y - horizonLine);
    
    // Calculate world space position
    vec2 worldPos;
    worldPos.x = (screen_coords.x - love_ScreenSize.x/2.0) * distance / love_ScreenSize.y;
    worldPos.y = distance;
    
    // Rotate around camera position
    float cosA = cos(cameraAngle);
    float sinA = sin(cameraAngle);
    vec2 rotated;
    rotated.x = worldPos.x * cosA - worldPos.y * sinA + cameraPos.x;
    rotated.y = worldPos.x * sinA + worldPos.y * cosA + cameraPos.y;
    
    // Sample texture
    vec2 texCoord = rotated / textureDimensions;
    vec4 texColor = Texel(tex, mod(texCoord, 1.0)) * color;
    
    // Apply distance-based fog
    float fogFactor = clamp(distance / maxDistance, 0.0, 1.0);
    fogFactor = smoothstep(0.0, 1.0, fogFactor);  // Smooth the transition
    
    // Mix between texture color and fog color
    return mix(texColor, vec4(fogColor, 1.0), fogFactor);
}





