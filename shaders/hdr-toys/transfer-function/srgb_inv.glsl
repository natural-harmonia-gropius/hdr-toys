// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lib/ACESlib.Utilities_Color.ctl
// moncurve with gamma of 2.4 and offset of 0.055 matches the EOTF found in IEC 61966-2-1:1999 (sRGB)

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (srgb, inverse)

float monitor_curve_eotf(float x, float gamma, float offset) {
    const float fs = ((gamma - 1.0) / offset) * pow(offset * gamma / ((gamma - 1.0) * (1.0 + offset)), gamma);
    const float xb = offset / (gamma - 1.0);
    return x >= xb ? pow((x + offset) / (1.0 + offset), gamma) : x * fs;
}

vec3 monitor_curve_eotf(vec3 color, float gamma, float offset) {
    return vec3(
        monitor_curve_eotf(color.r, gamma, offset),
        monitor_curve_eotf(color.g, gamma, offset),
        monitor_curve_eotf(color.b, gamma, offset)
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = monitor_curve_eotf(color.rgb, 2.4, 0.055);

    return color;
}
