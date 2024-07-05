varying float v_DistanceToCamera;

const float DEPTH_SCALE_FACTOR = 16777215.0;

vec3 toDepthColor(float depth) {
    float longDepth = depth * DEPTH_SCALE_FACTOR;
    vec3 depthAsColor = vec3(mod(longDepth, 256.0), mod(longDepth / 256.0, 256.0), longDepth / 65536.0);
    depthAsColor = floor(depthAsColor);
    depthAsColor /= 255.0;
    return depthAsColor;
}

const vec3 UNDO = vec3(1.0, 256.0, 65536.0) / 16777215.0 * 255.0;
float depthFromColor(vec3 color) {
    return dot(color, UNDO);
}

void main() {
    gl_FragColor = vec4(toDepthColor(v_DistanceToCamera), 1);
}