//!HOOK OUTPUT
//!BIND HOOKED
//!DESC srgb to linear

const float GAMMA  = 2.4;
const float OFFSET = 0.055;

// moncurve_r with gamma of 2.4 and offset of 0.055 matches the EOTF found in IEC 61966-2-1:1999 (sRGB)
float moncurve_f(float x, float gamma, float offs) {
    const float fs = ((gamma - 1.0) / offs) * pow(offs * gamma / ((gamma - 1.0) * (1.0 + offs)), gamma);
    const float xb = offs / (gamma - 1.0);
    return x >= xb ? pow((x + offs) / (1.0 + offs), gamma) : x * fs;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = vec3(
        moncurve_f(color.r, GAMMA, OFFSET),
        moncurve_f(color.g, GAMMA, OFFSET),
        moncurve_f(color.b, GAMMA, OFFSET)
    );
    return color;
}
