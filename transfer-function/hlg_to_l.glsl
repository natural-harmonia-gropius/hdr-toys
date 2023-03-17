//!HOOK OUTPUT
//!BIND HOOKED
//!DESC hybrid log–gamma to luminance

const float L_w   = 1000.0;
const float L_b   = 0.0;

const float alpha = L_w - L_b;
const float beta  = L_b;
const float gamma = 1.2 * pow(1.111, log2(L_w / 1000.0));

const float a = 0.17883277;
const float b = 1.0 - 4.0 * a;
const float c = 0.5 - a * log(4.0 * a);

// HLG EOTF (i.e. HLG inverse OETF followed by the HLG OOTF)
vec3 HLG_to_Y(vec3 HLG) {
    // HLG Inverse OETF scene-linear (non-linear signal value to scene linear)
    const vec3 sceneLinear = vec3(
        HLG.r >= 0.0 && HLG.r <= 0.5 ? pow(HLG.r, 2.0) / 3.0 : (exp((HLG.r - c) / a) + b) / 12.0,
        HLG.g >= 0.0 && HLG.g <= 0.5 ? pow(HLG.g, 2.0) / 3.0 : (exp((HLG.g - c) / a) + b) / 12.0,
        HLG.b >= 0.0 && HLG.b <= 0.5 ? pow(HLG.b, 2.0) / 3.0 : (exp((HLG.b - c) / a) + b) / 12.0
    );

    // HLG OOTF (scene linear to display linear)
    const float Y_s = dot(sceneLinear, vec3(0.2627, 0.6780, 0.0593));
    const vec3 displayLinear = alpha * pow(Y_s, gamma - 1) * sceneLinear + beta;

    return displayLinear;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = HLG_to_Y(color.rgb);
    return color;
}
