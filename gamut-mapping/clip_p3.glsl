// Simple conversion from BT.2020 to P3-D65 based on linear matrix transformation

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (clip, p3-d65)

mat3 M = mat3(
     1.3435782525843323,    -0.2821796705261358,   -0.06139858205819626,
    -0.06529745278911947,    1.0757879158485737,   -0.010490463059454953,
     0.0028217872617010073, -0.019598494524494182,  1.0167767072627931);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 color_src = color.rgb;
    vec3 color_dst = color_src * M;

    color.rgb = clamp(color_dst, 0.0, 1.0);

    return color;
}
