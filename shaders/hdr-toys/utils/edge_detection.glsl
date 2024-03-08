//!HOOK OUTPUT
//!BIND HOOKED
//!DESC edge detection

// Positive Laplacian
const mat3 k = mat3(
    0.0,  1.0, 0.0,
    1.0, -4.0, 1.0,
    0.0,  1.0, 0.0
);
const uvec2 k_size = uvec2(3, 3);
const vec2  k_size_h = vec2(k_size / 2);

vec4 hook() {
    vec4 color = vec4(vec3(0.0), 1.0);

    for (uint i = 0; i < k_size.x; i++)
        for (uint j = 0; j < k_size.y; j++)
            color.rgb += HOOKED_texOff(vec2(j, i) - k_size_h).rgb * k[i][j];

    return color;
}
