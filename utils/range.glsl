// from "full" to SMPTE "legal" signal range

//!PARAM BLACK
//!TYPE float
0.0625

//!PARAM WHITE
//!TYPE float
0.91796875

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= WHITE - BLACK;
    color.rgb += BLACK;
    return color;
}
