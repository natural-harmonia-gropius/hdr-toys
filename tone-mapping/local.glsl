//!HOOK OUTPUT
//!BIND HOOKED
//!COMPUTE 32 32
//!DESC tone mapping (local)

shared float L_max;

void metering() {
    ivec2 base = ivec2(gl_WorkGroupID) * ivec2(gl_WorkGroupSize);
    for (uint x = 0; x < gl_WorkGroupSize.x; x++) {
        for (uint y = 0; y < gl_WorkGroupSize.y; y++) {
            vec4 texelValue = texelFetch(HOOKED_raw, base + ivec2(x,y), 0);
            float L = max(max(texelValue.r, texelValue.g), texelValue.b);
            L_max = max(L_max, L);
        }
    }
}

float curve(float x) {
    const float w = L_max;
    const float simple = x / (1.0 + x);
    const float extended = simple * (1.0 + x / (w * w));
    return extended;
}

vec3 tone_mapping_max(vec3 RGB) {
    const float m = max(max(RGB.r, RGB.g), RGB.b);
    return RGB * curve(m) / m;
}

vec4 color = HOOKED_tex(HOOKED_pos);
void hook() {
    L_max = 1.0;

    metering();

    barrier();

    color.rgb = tone_mapping_max(color.rgb);

    imageStore(out_image, ivec2(gl_GlobalInvocationID), color);
}
