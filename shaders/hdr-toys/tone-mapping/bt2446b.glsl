// ITU-R BT.2446 Conversion Method B
// https://www.itu.int/pub/R-REP-BT.2446

//!PARAM reference_white
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 1000.0
203.0

//!PARAM contrast_ratio
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 100000000.0
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (bt.2446b)

const vec3 y_coef = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);
const float bridge_peak = 1000.0;
const float bridge_gamma = 1.2;
const float display_peak = 291.0;
const float display_gamma = 1.03;
const float sdr_peak = 100.0;
const float knee = 55.0;
const float shoulder = 16.49284154;

float curve(float Y) {
    // The report specifies an example logarithmic shoulder, not unique
    // coefficients. The shoulder is fitted to curve(291) = 100 cd/m^2;
    // this is an approximation to Fig. 6, with value and slope continuous
    // at 55 cd/m^2. shoulder is measured in cd/m^2.
    return Y <= knee ? Y : knee + shoulder * log(1.0 + (Y - knee) / shoulder);
}

vec3 tone_mapping(vec3 RGB) {
    RGB = max(RGB, 0.0);
    float Y = dot(RGB, y_coef);
    if (Y <= 0.0)
        return vec3(0.0);

    // hlg_inv.glsl uses a 1000-nit, gamma-1.2, zero-black HLG EOTF.
    // Undo its luminance OOTF and reinterpret the scene under method B's
    // 291-nit, gamma-1.03 display model (section 5.2.1).
    // For decoded PQ input, assume the same 1000-nit display-light bridge
    // to HLG. This is a fixed bridge assumption, not metadata adaptation.
    float Yscene = pow(Y * reference_white / bridge_peak, 1.0 / bridge_gamma);
    float Ydisplay = display_peak * pow(Yscene, display_gamma);
    float Ysdr = curve(Ydisplay);

    // Scaling all channels equally preserves XYZ chromaticity, including
    // u'v', and is equivalent to mapping only Y in Yu'v' (section 5.2.2).
    // Combine the display-model and tone-curve gains, then normalize SDR.
    return RGB * (Ysdr / (Y * sdr_peak));
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = tone_mapping(color.rgb);

    // Match the chain's black-point compensation before BT.1886 encoding.
    float black = contrast_ratio > 0.0 ? 1.0 / contrast_ratio : 0.0;
    color.rgb = color.rgb * (1.0 - black) + black;

    return color;
}
