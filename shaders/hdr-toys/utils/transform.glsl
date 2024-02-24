// https://developer.mozilla.org/en-US/docs/Web/CSS/transform

//!PARAM scale_x
//!TYPE float
1.0

//!PARAM scale_y
//!TYPE float
1.0

//!PARAM translate_x
//!TYPE float
0.0

//!PARAM translate_y
//!TYPE float
0.0

//!PARAM skew_x
//!TYPE float
0.0

//!PARAM skew_y
//!TYPE float
0.0

//!PARAM rotate
//!TYPE float
0.0

//!PARAM background
//!TYPE ENUM int
black
border
repeat
mirror

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transform

vec4 hook() {
    vec2 pos = HOOKED_pos;
    vec2 size = HOOKED_size;
    vec2 align = vec2(0.5, 0.5); // center

    pos -= align;

    if (scale_x != 1.0 || scale_y != 1.0)
        pos /= vec2(scale_x, scale_y);

    if (translate_x != 0.0 || translate_y != 0.0)
        pos -= vec2(translate_x, translate_y) * vec2(scale_x, scale_y);

    if (skew_x != 0.0 || skew_y != 0.0)
        pos = mat2(1.0, -tan(radians(skew_y)), -tan(radians(skew_x)), 1.0) * pos;

    if (rotate != 0.0) {
        pos *= size;
        float c = length(pos);
        float h = atan(pos.y, pos.x) - radians(rotate);
        float a = cos(h) * c;
        float b = sin(h) * c;
        pos = vec2(a, b);
        pos = floor(pos);
        pos /= size;
    }

    pos += align;

    if (background == black)
        if (pos != clamp(pos, 0.0, 1.0))
            return vec4(vec3(0.0), 1.0);
    else if (background == border)
        pos = clamp(pos, 0.0, 1.0);
    else if (background == repeat)
        pos = mod(pos, 1.0);
    else if (background == mirror)
        pos = abs(1.0 - abs(mod(pos, 2.0) - 1.0));

    return HOOKED_tex(pos);
}
