extern vec2 cameraPos;
extern float cameraAngle;
extern float cameraHeight;
extern float horizonLine;
extern float maxDistance;
extern vec3 fogColor;
extern float fogDampening;
extern float fogAlpha;
extern vec2 lightPositions[4];    // Array of light positions
extern vec3 lightColors[4];       // Array of light colors
extern float lightRadii[4];       // Array of light radii
extern vec3 ambientLight;
extern vec2 textureDimensions;
extern Image skyTexture;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Handle sky rendering above horizon
    if (screen_coords.y <= horizonLine) {
        vec2 skyCoord = vec2(texture_coords.x, screen_coords.y / horizonLine);
        vec4 skyColor = Texel(skyTexture, skyCoord);
        return vec4(mix(skyColor.rgb, fogColor, screen_coords.y / horizonLine), 1.0);
    }
    
    // Ground rendering below horizon (existing code)
    float distance = (cameraHeight * (love_ScreenSize.y - horizonLine)) 
                    / (screen_coords.y - horizonLine);
    
    // Calculate horizontal position relative to center of screen
    float screenX = screen_coords.x - love_ScreenSize.x/2;
    
    // Calculate world offset using both X and Y
    float scale = distance / love_ScreenSize.y;
    float dx = screenX * scale * sin(cameraAngle + 3.14159/2) + distance * sin(cameraAngle);
    float dy = screenX * scale * cos(cameraAngle + 3.14159/2) + distance * cos(cameraAngle);
    vec2 worldPos = cameraPos + vec2(dx, dy);
    
    // Calculate texture coordinates
    vec2 texCoords = mod(worldPos, textureDimensions) / textureDimensions;
    vec4 texColor = Texel(tex, texCoords);
    
    // Initialize lighting
    vec3 litColor = texColor.rgb * ambientLight;
    
    // Calculate lighting for all lights
    for (int i = 0; i < 4; i++) {
        float lightDist = length(worldPos - lightPositions[i]);
        float lightFactor = 1.0 - smoothstep(0.0, lightRadii[i], lightDist);
        litColor += texColor.rgb * lightColors[i] * lightFactor;
    }
    
    // Reduce fog strength by starting further and blending more gradually
    float fogFactor = smoothstep(maxDistance * fogDampening, maxDistance, distance) * fogAlpha;
    vec3 finalColor = mix(litColor, fogColor, fogFactor);
    
    return vec4(finalColor, 1.0);
}
