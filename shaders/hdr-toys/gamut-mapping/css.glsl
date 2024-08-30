//!HOOK OUTPUT
//!BIND HOOKED
//!BIND LUT
//!DESC lut

vec3 trilinearInterpolate(
    vec3 frac,
    vec3 color000, vec3 color100, vec3 color010, vec3 color001,
    vec3 color110, vec3 color101, vec3 color011, vec3 color111
) {
    // Interpolate along x-axis
    vec3 c00 = mix(color000, color100, frac.x);
    vec3 c10 = mix(color010, color110, frac.x);
    vec3 c01 = mix(color001, color101, frac.x);
    vec3 c11 = mix(color011, color111, frac.x);

    // Interpolate along y-axis
    vec3 c0 = mix(c00, c10, frac.y);
    vec3 c1 = mix(c01, c11, frac.y);

    // Interpolate along z-axis
    vec3 interpolatedColor = mix(c0, c1, frac.z);

    return interpolatedColor;
}

vec3 tetrahedralInterpolate(
    vec3 frac,
    vec3 color000, vec3 color100, vec3 color010, vec3 color001,
    vec3 color110, vec3 color101, vec3 color011, vec3 color111
) {
    vec3 interpolatedColor;

    if (frac.x >= frac.y) {
        if (frac.y >= frac.z) {
            // Region: (1,0,0), (1,1,0), (1,1,1), (0,1,1)
            vec3 c1 = mix(color000, color100, frac.x);
            vec3 c2 = mix(color110, color111, frac.z);
            interpolatedColor = mix(c1, c2, frac.y);
        } else if (frac.x >= frac.z) {
            // Region: (1,0,0), (1,0,1), (1,1,1), (0,1,1)
            vec3 c1 = mix(color000, color100, frac.x);
            vec3 c2 = mix(color101, color111, frac.y);
            interpolatedColor = mix(c1, c2, frac.z);
        } else {
            // Region: (0,0,1), (1,0,1), (1,1,1), (0,1,1)
            vec3 c1 = mix(color000, color001, frac.z);
            vec3 c2 = mix(color101, color111, frac.y);
            interpolatedColor = mix(c1, c2, frac.x);
        }
    } else {
        if (frac.z >= frac.y) {
            // Region: (0,0,1), (0,1,1), (1,1,1), (1,0,1)
            vec3 c1 = mix(color000, color001, frac.z);
            vec3 c2 = mix(color011, color111, frac.x);
            interpolatedColor = mix(c1, c2, frac.y);
        } else if (frac.z >= frac.x) {
            // Region: (0,0,1), (0,1,0), (1,1,1), (1,1,0)
            vec3 c1 = mix(color000, color010, frac.y);
            vec3 c2 = mix(color011, color111, frac.x);
            interpolatedColor = mix(c1, c2, frac.z);
        } else {
            // Region: (0,0,0), (0,1,0), (1,1,0), (1,1,1)
            vec3 c1 = mix(color000, color010, frac.y);
            vec3 c2 = mix(color110, color111, frac.z);
            interpolatedColor = mix(c1, c2, frac.x);
        }
    }

    return interpolatedColor;
}

// Function to apply 3D LUT using tetrahedral interpolation
vec3 applyLUT(vec3 color, sampler3D LUTTexture, float LUTSize) {
    // Scale the input color from [0.0, 1.0] to [0.0, LUTSize-1]
    vec3 scaledColor = color * (LUTSize - 1.0);

    // Calculate the integer coordinates of the LUT
    vec3 index = floor(scaledColor);

    // Calculate the fractional part of the coordinates (used for interpolation)
    vec3 frac = scaledColor - index;

    // Calculate the corner points in the LUT texture
    vec3 index000 = index / (LUTSize - 1.0);
    vec3 index100 = (index + vec3(1.0, 0.0, 0.0)) / (LUTSize - 1.0);
    vec3 index010 = (index + vec3(0.0, 1.0, 0.0)) / (LUTSize - 1.0);
    vec3 index001 = (index + vec3(0.0, 0.0, 1.0)) / (LUTSize - 1.0);
    vec3 index110 = (index + vec3(1.0, 1.0, 0.0)) / (LUTSize - 1.0);
    vec3 index101 = (index + vec3(1.0, 0.0, 1.0)) / (LUTSize - 1.0);
    vec3 index011 = (index + vec3(0.0, 1.0, 1.0)) / (LUTSize - 1.0);
    vec3 index111 = (index + vec3(1.0, 1.0, 1.0)) / (LUTSize - 1.0);

    // Fetch the LUT colors for each corner
    vec3 color000 = texture(LUTTexture, index000).rgb;
    vec3 color100 = texture(LUTTexture, index100).rgb;
    vec3 color010 = texture(LUTTexture, index010).rgb;
    vec3 color001 = texture(LUTTexture, index001).rgb;
    vec3 color110 = texture(LUTTexture, index110).rgb;
    vec3 color101 = texture(LUTTexture, index101).rgb;
    vec3 color011 = texture(LUTTexture, index011).rgb;
    vec3 color111 = texture(LUTTexture, index111).rgb;

    // Perform tetrahedral interpolation
    vec3 interpolatedColor = tetrahedralInterpolate(
        frac,
        color000, color100, color010, color001,
        color110, color101, color011, color111
    );

    // return interpolatedColor;
    return clamp(interpolatedColor, 0.0, 1.0);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = applyLUT(color.rgb, LUT, 33.0);
    return color;
}

//!TEXTURE LUT
//!SIZE 33 33 33
//!FORMAT rgba16f
//!FILTER LINEAR