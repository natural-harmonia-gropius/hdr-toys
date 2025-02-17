# HDR Toys

A set of color conversion shaders for mpv-player (gpu-next).

| R                                                                                                              | G                                                                                                              | B                                                                                                              |
| -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| ![屏幕截图 2024-10-21 220701](https://github.com/user-attachments/assets/8fce1636-1a8f-49d5-88b5-6dfd2b8c3e9e) | ![屏幕截图 2024-10-21 220729](https://github.com/user-attachments/assets/e9d68096-aeb6-4dd0-8d2c-3c20aa201b94) | ![屏幕截图 2024-10-21 220749](https://github.com/user-attachments/assets/9078074b-be86-408d-9dcb-9dd171fdcac6) |

For more detailed information, please visit the [wiki](https://github.com/natural-harmonia-gropius/hdr-toys/wiki).

## Getting Started

1. Download [hdr-toys.zip](https://github.com/natural-harmonia-gropius/hdr-toys/archive/refs/heads/master.zip), extract it.
2. Copy the `shaders`, `scripts`, and `hdr-toys.conf` files to your [mpv config folder](https://mpv.io/manual/master/#configuration-files).
3. Add `include=~~/hdr-toys.conf` to your `mpv.conf`.

## FAQ

- **Shader not working or looks incorrect.**

  This set of shaders is specifically designed for use with [**vo=gpu-next**](https://mpv.io/manual/master/#video-output-drivers-gpu-next). Make sure **NOT** to set `target-peak`, `icc-profile`, or similar options in `mpv.conf`.

  For a complete configuration example, check out [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config).

  If you've confirmed these settings and the problem persists, please submit an issue.

- **UI/OSD looks washed out.**

  To ensure the video input meets the standards, I use a little trick by setting `target-prim` and `target-trc` to match the input values. As a side effect, the OSD inevitably appears washed out.

- **What does hdr-toys.js do?**

  HDR videos generally include metadata with luminance information, but shaders cannot access this data directly. `hdr-toys.js` provides a way to indirectly pass the necessary information using the [glsl-shader-opts](https://mpv.io/manual/master/#options-glsl-shader-opts).

  It also passes the number of frames for 1/3 second to reduce flickering, helping to smooth out rapid brightness changes.

- **I feel the video always looks too dark.**

  This issue arises from the inability to determine the reference white of the video, which is unfortunately not included in the metadata.

  To adjust the reference white, add the following lines to `input.conf`. Press `n` when you feel so, and press `m` to restore to the default.

  ```ini
  n   set glsl-shader-opts reference_white=100
  m   set glsl-shader-opts reference_white=203
  ```

  Note that, due to a limitation in mpv, only parameters changed after the shader is applied will take effect. Therefore, setting `glsl-shader-opts=reference_white=100` in `mpv.conf` will not work.

- **I'm not using BT.709 display.**

  Replace all `gamut-mapping/*` lines with `gamut-mapping/clip.glsl`. Then modify the `#define to *` in `clip.glsl` to match your display.

- **I don't use mpv, can I use these shaders?**

  These shaders use [mpv .hook syntax](https://libplacebo.org/custom-shaders/), which requires `libplacebo` for execution. ffmpeg and VLC should be able to use. In theory, porting to other shader languages is also very feasible.
