#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float centerX;
    float centerY;
    float canvasWidth;
    float canvasHeight;
} ubuf;

layout(binding = 1) uniform sampler2D gradTex;

void main() {
    // Current pixel position normalized (0.0 to 1.0)
    vec2 pos = qt_TexCoord0;
    
    // Gradient center normalized (0.0 to 1.0)
    vec2 center = vec2(ubuf.centerX, ubuf.centerY);
    
    // Calculate distance vector
    vec2 d = pos - center;
    
    // Previous implementation had centerRadius = maxDim (the full width/height).
    // The distance from center to edge is 0.5 * maxDim.
    // So at the edge, the gradient position was (0.5 * maxDim) / maxDim = 0.5.
    // Normalized distance 'dist' at edge is 0.5.
    // To match previous behavior where edge = 0.5 gradient pos:
    // t = dist.
    
    float dist = length(d);
    
    float t = dist;
    
    // Clamp is strictly not necessary if texture wrap is ClampToEdge, but good for safety
    t = clamp(t, 0.0, 1.0);
    
    fragColor = texture(gradTex, vec2(t, 0.5)) * ubuf.qt_Opacity;
}
