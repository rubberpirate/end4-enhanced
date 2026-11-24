#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    vec4 anchor;
    vec4 anchorColor;
    vec4 drop0;
    vec4 drop1;
    vec4 drop2;
    vec4 drop3;
};
float box(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}
float melt(float a, float b, float k) {
    if (k <= 0.0) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k / 6.0;
}
float addDrop(float field, vec2 p, vec4 drop) {
    if (drop.y <= 0.0) return field;
    return melt(field, box(p - vec2(0.0, drop.x), drop.yz / 2.0, min(drop.y, drop.z) / 2.0), drop.w);
}
void main() {
    vec2 p = qt_TexCoord0 * resolution - vec2(resolution.x / 2.0, 0.0);
    float bottom = anchor.x + anchor.z;
    // The bar already paints the island and its widgets. Only paint its liquid extension.
    if (p.y < bottom) { fragColor = vec4(0.0); return; }
    float d = anchor.y > 0.0 ? box(p - vec2(0.0, anchor.x), anchor.yz, anchor.w) : 100000.0;
    d = addDrop(d, p, drop0);
    d = addDrop(d, p, drop1);
    d = addDrop(d, p, drop2);
    d = addDrop(d, p, drop3);
    float edge = max(fwidth(d), 0.5);
    float alpha = (1.0 - smoothstep(-edge / 2.0, edge / 2.0, d)) * qt_Opacity;
    float neckLength = max(drop0.x - drop0.z / 2.0 - bottom, 1.0);
    vec3 color = mix(anchorColor.rgb, vec3(0.0), clamp((p.y - bottom) / neckLength, 0.0, 1.0));
    fragColor = vec4(color * alpha, alpha);
}
