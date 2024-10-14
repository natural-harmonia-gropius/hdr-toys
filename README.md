# HDR Toys

A set of color conversion shaders for mpv-player (gpu-next).

For more detailed information, please refer to the [wiki](https://github.com/natural-harmonia-gropius/hdr-toys/wiki).

## Getting started

1. Download [hdr-toys.zip](https://github.com/natural-harmonia-gropius/hdr-toys/archive/refs/heads/master.zip), extract it and copy `shaders`, `scripts` and `hdr-toys.conf` to your mpv config folder.
2. Append `include=~~/hdr-toys.conf` to your `mpv.conf`

## FAQ

- **Shader not working / looks very wrong.**

  This set of shaders is designed for use with [**vo=gpu-next**](https://mpv.io/manual/master/#video-output-drivers-gpu-next). Also, **DO NOT** set `target-peak`, `icc-profile`, or other similar settings in in mpv.conf.

  For a complete usage example, refer to [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config)

  If you've confirmed these settings but still don't get the correct result, please submit an issue.

- **What does hdr-toys.js do?**

  HDR videos generally include metadata with luminance information. However, shaders cannot access this information directly, so hdr-toys.js provides an indirect way to retrieve it.

- **I feel the video is always dark.**

  This issue arises from the inability to determine the reference white of the video, which is unfortunately not included in the metadata.

  To adjust the reference white, append the following lines to input.conf.
  Press `n` when you feel so, press `m` to restore to default.

  ```ini
  n   set glsl-shader-opts L_sdr=100
  m   set glsl-shader-opts L_sdr=203
  ```

  Due to an issue with mpv, only parameters changed after the shader is applied will take effect, so `glsl-shader-opts=L_sdr=100` in mpv.conf will not work.

- **I'm not using BT.709 display.**

  Replace all `gamut-mapping/*` lines with `gamut-mapping/clip.glsl`.  
  Then change `#define to *` in clip.glsl to match your display.

- **I don't use mpv, can I use this set of shaders?**

  The main dependency is libplacebo, ffmpeg and VLC should be able to use. In theory, porting to other shader languages is also very feasible.
