// Simple conversion from BT.2020 to BT.709 based on linear matrix transformation

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (clip)

mat3 M = mat3(
     1.6604910021084354,  -0.5876411387885495,  -0.07284986331988474,
    -0.12455047452159074,  1.1328998971259596,  -0.008349422604369515,
    -0.01815076335490526, -0.10057889800800737,  1.118729661362913);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 color_src = color.rgb;
    vec3 color_dst = color_src * M;

    color.rgb = clamp(color_dst, 0.0, 1.0);

    return color;
}
