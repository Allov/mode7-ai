uniform vec2 cameraPos;
uniform float cameraAngle;
uniform float cameraHeight;
uniform float horizonLine;
uniform vec2 textureDimensions;
uniform float maxDistance;
uniform vec3 fogColor;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Skip pixels above horizon
    if (screen_coords.y < horizonLine) {
        return vec4(fogColor, 1.0);
    }
    
    // Use higher precision for distance calculation
    float distance = (cameraHeight * (love_ScreenSize.y - horizonLine)) 
                    / max(screen_coords.y - horizonLine, 0.001); // Prevent division by zero
    
    // Improve precision for world position calculation
    vec2 worldPos;
    float aspectRatio = love_ScreenSize.x / love_ScreenSize.y;
    worldPos.x = (screen_coords.x - love_ScreenSize.x * 0.5) * distance * aspectRatio / love_ScreenSize.y;
    worldPos.y = distance;
    
    // Use precise rotation matrix
    float cosA = cos(cameraAngle);
    float sinA = sin(cameraAngle);
    vec2 rotated = vec2(
        worldPos.x * cosA - worldPos.y * sinA,
        worldPos.x * sinA + worldPos.y * cosA
    );
    
    // Add camera position after rotation to reduce floating point errors
    rotated += cameraPos;
    
    // Apply anti-aliasing to texture sampling
    vec2 texCoord = rotated / textureDimensions;
    vec2 texelSize = 1.0 / textureDimensions;
    vec2 frac = fract(texCoord * textureDimensions);
    
    // Bilinear filtering for smoother texture sampling
    vec2 texCoord1 = floor(texCoord * textureDimensions) / textureDimensions;
    vec2 texCoord2 = texCoord1 + vec2(texelSize.x, 0.0);
    vec2 texCoord3 = texCoord1 + vec2(0.0, texelSize.y);
    vec2 texCoord4 = texCoord1 + texelSize;
    
    vec4 s1 = Texel(tex, mod(texCoord1, 1.0));
    vec4 s2 = Texel(tex, mod(texCoord2, 1.0));
    vec4 s3 = Texel(tex, mod(texCoord3, 1.0));
    vec4 s4 = Texel(tex, mod(texCoord4, 1.0));
    
    vec4 texColor = mix(
        mix(s1, s2, frac.x),
        mix(s3, s4, frac.x),
        frac.y
    ) * color;
    
    // Smooth fog transition
    float fogStart = maxDistance * 0.6; // Start fog earlier
    float fogFactor = smoothstep(fogStart, maxDistance, distance);
    
    return mix(texColor, vec4(fogColor, 1.0), fogFactor);
}

