// The crosstalk matrix is applied such that saturations of
// linear signals are reduced to achromatic to avoid hue
// changes caused by clipping of compressed highlight parts.

//!PARAM crosstalk_intensity
//!TYPE float
//!MINIMUM 0.00
//!MAXIMUM 0.33
0.04

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN crosstalk_intensity
//!DESC crosstalk

vec3 crosstalk(vec3 x, float a) {
    float b = 1.0 - 2.0 * a;
    return vec3(
        x.x * b + (x.y + x.z) * a,
        x.y * b + (x.x + x.z) * a,
        x.z * b + (x.x + x.y) * a
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = crosstalk(color.rgb, crosstalk_intensity);

    return color;
}
