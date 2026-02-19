#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float angle;
    float canvasWidth;
    float canvasHeight;
} ubuf;

layout(binding = 1) uniform sampler2D gradTex;

void main() {
    vec2 size = vec2(ubuf.canvasWidth, ubuf.canvasHeight);
    vec2 center = size * 0.5;
    vec2 pos = qt_TexCoord0 * size;
    vec2 relPos = pos - center;

    float angleRad = radians(ubuf.angle);
    vec2 dir = vec2(sin(angleRad), cos(angleRad));

    vec2 corners[4];
    corners[0] = vec2(0, 0) - center;
    corners[1] = vec2(size.x, 0) - center;
    corners[2] = vec2(0, size.y) - center;
    corners[3] = vec2(size.x, size.y) - center;

    float minProj = dot(corners[0], dir);
    float maxProj = minProj;
    for(int i=1; i<4; i++) {
        float p = dot(corners[i], dir);
        minProj = min(minProj, p);
        maxProj = max(maxProj, p);
    }

    float proj = dot(relPos, dir);
    float t = (proj - minProj) / (maxProj - minProj);
    
    t = clamp(t, 0.0, 1.0);

    fragColor = texture(gradTex, vec2(t, 0.5)) * ubuf.qt_Opacity;
}
