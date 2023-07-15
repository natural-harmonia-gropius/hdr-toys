// The simplest tone mapping method, just multiplied by a number.

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
//!DESC tone mapping (linear)

float curve(float x) {
    const float w = L_hdr / L_sdr;
    return x / w;
}

vec3 tone_mapping_y(vec3 RGB) {
    const float y = dot(RGB, vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196));
    return RGB * curve(y) / y;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = tone_mapping_y(color.rgb);
    return color;
}
