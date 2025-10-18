# HDR Toys

A set of color conversion shaders for mpv-player (gpu-next).

For more detailed information, please visit the [wiki](https://github.com/natural-harmonia-gropius/hdr-toys/wiki).

|                                                                                                                        |                                                                                                                        |                                                                                                                        |
| ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| <img width="1920" alt="image" src="https://github.com/user-attachments/assets/2ee1f4af-9ef3-4cae-a8f2-3ac4412a8a6f" /> | <img width="1920" alt="image" src="https://github.com/user-attachments/assets/93997a25-1adc-43f9-ae3d-548477075b0f" /> | <img width="1920" alt="image" src="https://github.com/user-attachments/assets/b7d81ffe-ff03-4e4c-98bd-daaf142ca83b" /> |

## Getting Started

1. Download [hdr-toys.zip](https://github.com/natural-harmonia-gropius/hdr-toys/archive/refs/heads/master.zip), extract it.
2. Copy the `shaders`, `scripts`, and `hdr-toys.conf` files to your [mpv config folder](https://mpv.io/manual/master/#configuration-files).
3. Add `include=~~/hdr-toys.conf` to your `mpv.conf`.

## FAQ

- **Shader not working or looks incorrect.**

  This set of shaders is specifically designed for use with [**vo=gpu-next**](https://mpv.io/manual/master/#video-output-drivers-gpu-next). Make sure **NOT** to set `target-peak`, `icc-profile`, or similar options in `mpv.conf`.

  For a complete configuration example, check out [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config).

  If you've confirmed these settings and the problem persists, please submit an issue.

  You may notice black areas in files with linear light input (such as OpenEXR), which is due to the limitations of 16-bit floating-point values.

- **UI/OSD looks washed out.**

  To ensure the video input meets the standards, I use a little trick by setting `target-prim` and `target-trc` to match the input values. As a side effect, the OSD appears washed out, I currently have no solution.

- **I'm using an HDR/WCG display.**

  Use PQ as the transfer function instead of BT.1886, and set the reference white to match your display's peak brightness. (This may behave unexpectedly for various reasons. Be cautious—it could produce extreme output.)

  ```ini
  target-colorspace-hint=yes
  ...
  glsl-shader=~~/shaders/hdr-toys/transfer-function/pq.glsl
  glsl-shader-opts-append=reference_white=1000
  glsl-shader-opts-append=contrast_ratio=1000000
  ```

  Replace all `gamut-mapping/*` lines in `hdr-toys.conf` with `gamut-mapping/clip.glsl`. Then modify the `#define to *` in `clip.glsl` to match your display's gamut.

  ```ini
  glsl-shader=~~/shaders/hdr-toys/gamut-mapping/clip.glsl
  ```

  ```glsl
  #define from    BT2020
  #define to      P3D65
  ```

  When to is equal to from (e.g., `#define to BT2020`), you can comment out or remove these gamut-mapping lines in the conf.

- **I want the image to look more filmic.**

  Add the following parameters to the conf file.

  ```ini
  glsl-shader-opts-append=auto_exposure_anchor=0.5
  glsl-shader-opts-append=contrast_bias=0.07
  glsl-shader-opts-append=chroma_correction_scaling=1.33
  ```

- **What does hdr-toys.lua do?**

  This provides a way to indirectly pass the necessary information using the [glsl-shader-opts](https://mpv.io/manual/master/#options-glsl-shader-opts).

  - the number of frames for 1/3 second, for reduce flickering.

- **I don't use mpv, can I use these shaders?**

  These shaders use [mpv .hook syntax](https://libplacebo.org/custom-shaders/), which requires `libplacebo` for execution. ffmpeg and VLC should be able to use. In theory, porting to other shader like languages is very feasible.
