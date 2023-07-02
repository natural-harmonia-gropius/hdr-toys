// from "full" to SMPTE "legal" signal range

//!PARAM signal_black
//!TYPE float
0.0625

//!PARAM signal_white
//!TYPE float
0.91796875

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= signal_white - signal_black;
    color.rgb += signal_black;
    return color;
}
