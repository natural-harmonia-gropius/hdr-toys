// ST 2094-40:2020 - SMPTE Standard - Dynamic Metadata for Color Volume Transform - Application #4
// https://ieeexplore.ieee.org/document/9095450

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (st2094-40)

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_YCbCr(color.rgb);
    color.rgb = tone_mapping(color.rgb);
    color.rgb = YCbCr_to_RGB(color.rgb);

    return color;
}
