// Reinhard tone mapping curve applied to max rgb (ARRI AWG4)

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
//!DESC tone mapping (reinhard, max rgb)

const mat3 BT2020_to_AWG4 = mat3(
    0.895475, 0.043615, 0.060910,
    0.044506, 0.854567, 0.100927,
    0.000000, 0.025777, 0.974223
);

const mat3 AWG4_to_BT2020 = mat3(
     1.119469, -0.055196, -0.064273,
    -0.058484,  1.176735, -0.118250,
     0.001547, -0.031135,  1.029588
);

float curve(float x, float w) {
    float simple = x / (1.0 + x);
    float extended = simple * (1.0 + x / (w * w));
    return extended;
}

vec3 tone_mapping(vec3 color, vec3 w) {
    float m = max(max(color.r, color.g), color.b);
    float a = max(max(w.r, w.g), w.b);
    vec3  c = color * curve(m, a) / max(m, 1e-6);
    return mix(c, m / w, m / a);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb *= BT2020_to_AWG4;
    color.rgb  = tone_mapping(color.rgb, vec3(L_hdr / L_sdr) * BT2020_to_AWG4);
    color.rgb *= AWG4_to_BT2020;

    return color;
}
