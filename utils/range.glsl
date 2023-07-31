// from "full" to SMPTE "legal" signal range

//!PARAM black
//!TYPE float
0.0625

//!PARAM white
//!TYPE float
0.91796875

//!PARAM depth
//!TYPE int
10

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float l = pow(2, depth);
    const float d = l - 1;
    const float b = l * black / d;
    const float w = l * white / d;

    color.rgb *= w - b;
    color.rgb += b;

    return color;
}
