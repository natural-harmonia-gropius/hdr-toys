// The inverse crosstalk matrix is applied to ensure that
// the original hues of input HDR images are recovered.

//!PARAM crosstalk_intensity
//!TYPE float
//!MINIMUM 0.00
//!MAXIMUM 0.33
0.04

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN crosstalk_intensity
//!DESC crosstalk (inverse)

vec3 crosstalk_inv(vec3 x, float a) {
    float b = 1.0 - a;
    float c_inv = 1.0 / (1.0 - 3.0 * a);
    return vec3(
        (x.x * b - (x.y + x.z) * a) * c_inv,
        (x.y * b - (x.x + x.z) * a) * c_inv,
        (x.z * b - (x.x + x.y) * a) * c_inv
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = crosstalk_inv(color.rgb, crosstalk_intensity);

    return color;
}
