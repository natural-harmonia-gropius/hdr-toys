// https://www.arib.or.jp/kikaku/kikaku_hoso/std-b67.html
// https://www.itu.int/rec/R-REC-BT.2100

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (hlg, inverse)

const vec3 RGB_to_Y = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

const float Lw   = 1000.0;
const float Lb   = 0.0;

const float gamma = 1.2 + 0.42 * log(Lw / 1000.0) / log(10.0);
const float alpha = Lw;
const float beta  = sqrt(3.0 * pow((Lb / Lw), 1.0 / gamma));

const float a = 0.17883277;
const float b = 1.0 - 4.0 * a;
const float c = 0.5 - a * log(4.0 * a);

float hlg_oetf_inv(float x) {
    return x <= 1.0 / 2.0 ? pow(x, 2.0) / 3.0 : (exp((x - c) / a) + b) / 12.0;
}

vec3 hlg_oetf_inv(vec3 color) {
    return vec3(
        hlg_oetf_inv(color.r),
        hlg_oetf_inv(color.g),
        hlg_oetf_inv(color.b)
    );
}

vec3 hlg_ootf(vec3 color) {
    float Y = dot(color, RGB_to_Y);
    return alpha * pow(Y, gamma - 1.0) * color;
}

vec3 hlg_eotf(vec3 color) {
    return hlg_ootf(hlg_oetf_inv(max((1.0 - beta) * color + beta, 0.0)));
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = hlg_eotf(color.rgb) / L_sdr;

    return color;
}
