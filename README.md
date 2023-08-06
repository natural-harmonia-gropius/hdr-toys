# HDR Toys

Componentized Rec.2100 to Rec.709 conversion shader for mpv-player.  
Featuring dynamic curves and a uniform color space.

## Getting started

> **Note**  
> `vo=gpu-next` is required.  
> Recommended to use the git version of mpv.  
> For full config see [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config)

1. Download [hdr-toys.zip](https://github.com/natural-harmonia-gropius/hdr-toys/archive/refs/heads/master.zip), extract it and rename it to `hdr-toys/` then put it in `~~/shaders`.
2. Download [hdr-toys-helper.lua](https://github.com/natural-harmonia-gropius/mpv-config/blob/master/portable_config/scripts/hdr-toys-helper.lua) and put it in `~~/scripts`
3. Append the following profiles to your `mpv.conf`

```ini
[bt.2100-pq]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/gamma") == "pq"
profile-restore=copy
target-prim=bt.2020
target-trc=pq
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_inv.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/jedypod.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886.glsl

[bt.2100-hlg]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/gamma") == "hlg"
profile-restore=copy
target-prim=bt.2020
target-trc=hlg
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/hlg_inv.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/jedypod.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886.glsl

[bt.2020]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/gamma") == "bt.1886"
profile-restore=copy
target-prim=bt.2020
target-trc=bt.1886
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886_inv.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bottosson.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886.glsl
```

- Dolby Vision Profile 5 is not tagged as HDR, so it wouldn't activate any auto-profile.
- Don't set target-peak, icc-profile...  
  Make sure there are **no** built-in tone map, gamut map, 3DLUT... in "Frame Timings" page.
- If you are not using a BT.709 display, replace all gamut-mapping/\* with `gamut-mapping/clip_custom.glsl`. Then set `to` in clip_custom.glsl to match your display.

## Detailed information

### Tone mapping

- HDR peak defaults to 1000nit, should be the max luminance of video.  
  hdr-toys-helper.lua can get it automatically from video-out-params/sig-peak.  
  You can set it manually with `set glsl-shader-opts L_hdr=N`

- SDR peak defaults to 203nit, should be the reference white of video.  
  In many videos it is 100nit and if so you'll get a dim result.  
  Unfortunately you have to guess the value and set it manually.  
  You can set it manually with `set glsl-shader-opts L_sdr=N`

You can change the tone mapping operator by replacing this line.  
For example, use bt2446c instead of dynamic.

```diff
- glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
+ glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
```

This table lists the features of operators.  
Operators below the blank row are for testing and should not be used for watching.

| Operator | Applied to | Conversion peak |
| -------- | ---------- | --------------- |
| dynamic  | JzCzhz     | Frame peak      |
| bt2390   | ICtCp      | HDR peak        |
| bt2446a  | YCbCr      | HDR peak        |
| bt2446c  | xyY        | 1000nit         |
| reinhard | YRGB       | HDR peak        |
| hable    | YRGB       | HDR peak        |
| hable2   | YRGB       | HDR peak        |
| lottes   | maxRGB     | HDR peak        |
| hejl2015 | RGB        | HDR peak        |
|          |            |                 |
| clip     | RGB        | SDR peak        |
| linear   | YRGB       | HDR peak        |
| false    | Y          | Infinity        |
| local    | YRGB       | Block peak      |

Typical representation of the same curve applied to different color spaces.
| RGB | YRGB | maxRGB | Hybrid in JzCzhz |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216764535-6bd0b74e-9b60-4743-9b25-dc7988fd0a8a.png) | ![image](https://user-images.githubusercontent.com/50797982/216764516-0cce4ddc-a414-47f1-9d9e-0b10aacee78b.png) | ![image](https://user-images.githubusercontent.com/50797982/216764500-24bf11c5-a480-44a5-99c7-853ebaa63744.png) | ![image](https://user-images.githubusercontent.com/50797982/216764489-0fe2cff9-cbb9-4f81-a9de-de3b333a5860.png) |

Typical representation of static and dynamic curves applied to the same color space.
| bt.2446c | dynamic | bt.2446c | dynamic | bt.2446c | dynamic |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216832251-abf05c55-bc97-48e4-97c8-a9b06240f235.png) | ![image](https://user-images.githubusercontent.com/50797982/216832261-93d7dcd4-7588-4086-a4dd-fb48d29c0ade.png) | ![image](https://user-images.githubusercontent.com/50797982/216901529-fa175d65-1fc8-4efe-a5e3-df7d63b4c800.png) | ![image](https://user-images.githubusercontent.com/50797982/216901584-93ffdbae-4f70-4b81-a978-d0fe69e06a39.png) | ![image](https://user-images.githubusercontent.com/50797982/216832312-9a3e1a9f-2dd0-4b28-abd0-b09b5aa45399.png) | ![image](https://user-images.githubusercontent.com/50797982/216832291-fbee6755-b028-4ede-a330-bccf0904a5b3.png) |

### Chroma correction

This is a part of tone mapping, also known as "highlights desaturate".  
You can set the intensity of it by `set glsl-shader-opts sigma=N`.

In real world, the brighter the color, the less saturated it becomes, and eventually it turns white.

| `sigma=0`                                                                                                       | `sigma=0.2`                                                                                                     | `sigma=1`                                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216247628-8647c010-ff70-488c-bc40-1d57612d1d9f.png) | ![image](https://user-images.githubusercontent.com/50797982/216247654-fc3066a1-098b-4f81-b4c5-a9c8eb6720cd.png) | ![image](https://user-images.githubusercontent.com/50797982/216247675-71c50982-2061-49b1-93b7-87ebe85951d6.png) |

<!--
### Crosstalk

This is a part of tone mapping, the screenshot below will show you how it works.
You can set the intensity of it by `set glsl-shader-opts alpha=N`.

It makes the color less chromatic when tone mapping and the lightness between colors more even.
And for some conversions like hejl2015, it brings achromatically highlights.

| without crosstalk inverse                                                                                       | `alpha=0` with heatmap                                                                                          | `alpha=0.3` with heatmap                                                                                        | `alpha=0` with hejl2015                                                                                         | `alpha=0.3` with hejl2015                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/213441412-7f43f19c-afc3-4b31-8b5c-55c1ac064ff7.png) | ![image](https://user-images.githubusercontent.com/50797982/213441611-fd6e6afa-e39b-4a44-82da-45a667dfe88a.png) | ![image](https://user-images.githubusercontent.com/50797982/213441631-3f87b965-8206-4e91-a8dd-d867c07cbf0d.png) | ![image](https://user-images.githubusercontent.com/50797982/213442007-411fd942-c930-4629-8dc1-88da8705639e.png) | ![image](https://user-images.githubusercontent.com/50797982/213442036-45e0a832-7d14-40f5-b4ca-1320ad59358d.png) |
-->

### Gamut mapping

`clip` is the exact conversion.  
`bottosson` clip out of gamut colors using Oklab.  
`jedypod` compress out of threshold colors by distance from achromatic axis.  
`false` shows the excess color after conversion as inverse color.

| clip                                                                                                                | bottosson                                                                                                           | jedypod                                                                                                             | false                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/d5cfa864-a21a-49b4-9343-dc4fba03b64a) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/52dd7ce8-0abf-4096-b9ee-1fcfcccaa81f) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/73b721da-6cf4-4ada-a80b-e6bec500b8b5) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/a6a2784a-7357-4438-b561-03b588002635) |

- The result of `clip` is different from libplacebo, which is due to the black point of BT.1886.  
  I consider that the black point should be set to zero for transcoding and conversion.
