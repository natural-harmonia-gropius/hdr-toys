// invert the signal

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal invert

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = -color.rgb + 1.0;

    return color;
}
