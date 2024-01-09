//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (black)

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = max(color.rgb, 0.0);

    return color;
}
