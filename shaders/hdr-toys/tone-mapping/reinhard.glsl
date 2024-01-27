// Extended mapping by Reinhard et al. 2002. which allows high luminances to burn out.
// https://www.researchgate.net/publication/2908938_Photographic_Tone_Reproduction_For_Digital_Images

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
//!DESC tone mapping (reinhard)

const vec3 RGB_to_Y = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

float curve(float x) {
    float w = L_hdr / L_sdr;
    float simple = x / (1.0 + x);
    float extended = simple * (1.0 + x / (w * w));
    return extended;
}

vec3 tone_mapping_y(vec3 RGB) {
    float y = dot(RGB, RGB_to_Y);
    return RGB * curve(y) / y;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = tone_mapping_y(color.rgb);

    return color;
}
