//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (white)

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = min(color.rgb, 1.0);

    return color;
}
