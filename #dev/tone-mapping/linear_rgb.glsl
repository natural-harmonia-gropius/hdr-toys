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
//!DESC tone mapping (linear, RGB pre-channel)

float curve(float x) {
    const float w = L_hdr / L_sdr;
    return x / w;
}

vec3 tone_mapping_rgb(vec3 RGB) {
    return vec3(curve(RGB.r), curve(RGB.g), curve(RGB.b));
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = tone_mapping_y(color.rgb);

    return color;
}
