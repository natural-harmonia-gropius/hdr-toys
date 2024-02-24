// from SMPTE "legal" to "full" signal range

//!PARAM black
//!TYPE float
0.0625

//!PARAM white
//!TYPE float
0.91796875

//!PARAM depth
//!TYPE float
10.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling (inverse)

float range_inv(float x, float w, float b) {
    return (x - b) / (w - b);
}

vec3 range_inv(vec3 x, float w, float b) {
    return (x - b) / (w - b);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    float l = pow(2.0, depth);
    float d = l - 1.0;
    float b = l * black / d;
    float w = l * white / d;

    color.rgb = range_inv(color.rgb, w, b);

    return color;
}
