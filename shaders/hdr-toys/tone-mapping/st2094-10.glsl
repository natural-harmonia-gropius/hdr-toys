// ST 2094-10:2021 - SMPTE Standard - Dynamic Metadata for Color Volume Transform - Application #1
// https://ieeexplore.ieee.org/document/9405553

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

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (st2094-10)

const vec3 RGB_to_Y = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

float curve(float x) {
    float n = 1.0;  // contrast [0.5, 1.5]
    float o = 0.0;  // offset   [-0.5, 0.5]
    float g = 1.0;  // gain     [0.5, 1.5]
    float p = 1.0;  // gamma    [0.5, 1.5]

    float x1 = 0.0;
    float y1 = 1.0 / CONTRAST_sdr;

    float x3 = L_hdr / L_sdr;
    float y3 = 1.0;

    float x2 = 0.7;  // TODO: input image essence average luminance value
    float y2 = min(sqrt(x2 * sqrt(y3 * y1)), 0.8 * y3);

    float a = x3 * y3 * (x1 - x2) + x2 * y2 * (x3 - x1) + x1 * y1 * (x2 - x3);

    mat3 cmat = mat3(
        x2 * x3 * (y2 - y3), x1 * x3 * (y3 - y1), x1 * x2 * (y1 - y2),
        x3 * y3 - x2 * y2  , x1 * y1 - x3 * y3  , x2 * y2 - x1 * y1  ,
        x3 - x2            , x1 - x3            , x2 - x1
    );

    vec3 coeffs = vec3(y1, y2, y3) * cmat / a;

    float c1 = coeffs.r;
    float c2 = coeffs.g;
    float c3 = coeffs.b;

    x = (c1 + c2 * pow(x, n)) / (1.0 + c3 * pow(x, n));
    x = pow(min(max(((x / y3) * g) + o, 0.0), 1.0), p) * y3;

    return x;
}

vec3 tone_mapping_y(vec3 RGB) {
    float y = dot(RGB, RGB_to_Y);
    return RGB * curve(y) / y;
}

vec3 gamut_adjustment(vec3 f) {
    float c = 0.0;  // chroma compensation weight   [-0.5, 0.5]
    float s = 0.0;  // saturation gain              [-0.5, 0.5]
    float y = dot(f, RGB_to_Y);
    return f * pow((1.0 + c) * f / y, vec3(s));
}

vec3 detail_managenment(vec3 p) {
    float t = 0.0;  // tone detail factor [0, 1];
    vec3 q = p;     // TODO: do what???
    return mix(p, q, t);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = tone_mapping_y(color.rgb);
    color.rgb = gamut_adjustment(color.rgb);
    color.rgb = detail_managenment(color.rgb);

    return color;
}
