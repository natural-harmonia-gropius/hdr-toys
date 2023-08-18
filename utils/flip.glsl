// horizonal flips (or mirrors) the video left to right.
// vertical flips the video top to bottom.

//!PARAM horizonal
//!TYPE int
0

//!PARAM vertical
//!TYPE int
0

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN horizonal vertical +
//!DESC flip

vec4 hook() {
    return HOOKED_tex(abs(vec2(horizonal, vertical) - HOOKED_pos));
}
