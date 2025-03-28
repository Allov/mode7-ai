uniform vec2 cameraPos;
uniform float cameraAngle;
uniform float cameraHeight;
uniform float horizonLine;
uniform vec2 textureDimensions;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Skip pixels above horizon
    if (screen_coords.y < horizonLine) {
        return vec4(0.0);
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
    return Texel(tex, mod(texCoord, 1.0)) * color;
}




