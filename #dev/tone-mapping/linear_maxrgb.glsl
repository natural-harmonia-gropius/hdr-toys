//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (linear，maxRGB)

float curve(float x) {
    const float w = L_hdr / L_sdr;
    return x / w;
}

vec3 tone_mapping_max(vec3 RGB) {
    const float m = max(max(RGB.r, RGB.g), RGB.b);
    return RGB * curve(m) / m;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = tone_mapping_max(color.rgb);

    return color;
}
