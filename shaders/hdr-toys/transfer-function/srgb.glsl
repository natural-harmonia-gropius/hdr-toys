// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lib/ACESlib.Utilities_Color.ctl
// moncurve with gamma of 2.4 and offset of 0.055 matches the EOTF found in IEC 61966-2-1:1999 (sRGB)

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (srgb)

float monitor_curve_eotf_inv(float y, float gamma, float offset) {
    const float yb = pow(offset * gamma / ((gamma - 1.0) * (1.0 + offset)), gamma);
    const float rs = pow((gamma - 1.0) / offset, gamma - 1.0) * pow((1.0 + offset) / gamma, gamma);
    return y >= yb ? (1.0 + offset) * pow(y, 1.0 / gamma) - offset : y * rs;
}

vec3 monitor_curve_eotf_inv(vec3 color, float gamma, float offset) {
    return vec3(
        monitor_curve_eotf_inv(color.r, gamma, offset),
        monitor_curve_eotf_inv(color.g, gamma, offset),
        monitor_curve_eotf_inv(color.b, gamma, offset)
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = monitor_curve_eotf_inv(color.rgb, 2.4, 0.055);

    return color;
}
