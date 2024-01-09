// https://en.wikipedia.org/wiki/Exposure_value

//!PARAM ev
//!TYPE float
//!MINIMUM -64
//!MAXIMUM  64
0

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN ev
//!DESC exposure

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb *= exp2(ev);

    return color;
}
