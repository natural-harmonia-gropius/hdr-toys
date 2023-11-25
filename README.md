# HDR Toys

Componentized Rec.2100 to Rec.709 conversion shader for mpv-player.  
Featuring dynamic curves and a uniform color space.

## Getting started

> [!Important]
> Requires [**_vo=gpu-next_**](https://mpv.io/manual/master/#video-output-drivers-gpu-next).

> [!Tip]
> Full portable_config: [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config).

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
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/jedypod.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886.glsl

[dovi-p5]
profile-cond=get("video-params/primaries") == "bt.709" and get("video-params/gamma") == "bt.1886" and get("video-out-params/max-luma") > 203
profile-restore=copy
target-prim=bt.2020
target-trc=pq
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_inv.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/dynamic.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/jedypod.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886.glsl
```

- Don't set target-peak, icc-profile...  
  Make sure there are _**no**_ built-in tone map, gamut map, 3DLUT... in "Frame Timings" page.
- If you are not using a BT.709 display, replace all gamut-mapping/\* with `gamut-mapping/clip.glsl`.  
  Then change `#define to *` to match your display.

## Detailed information

Most shaders have a link at the top, if you want to go deeper, you can visit it.

- About how to set parameters, see: [--glsl-shader-opts](https://mpv.io/manual/master/#options-glsl-shader-opts)

### Tone mapping

- HDR peak defaults to 1000nit, should be the max luminance of video.  
  hdr-toys-helper.lua can get it automatically from mpv.  
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
| linear   | ICtCp      | HDR peak        |
| clip     | RGB        | SDR peak        |
| false    | Heatmap    | Infinity        |

Typical representation of the same curve applied to different color spaces.
| RGB | YRGB | maxRGB | Hybrid in JzCzhz |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216764535-6bd0b74e-9b60-4743-9b25-dc7988fd0a8a.png) | ![image](https://user-images.githubusercontent.com/50797982/216764516-0cce4ddc-a414-47f1-9d9e-0b10aacee78b.png) | ![image](https://user-images.githubusercontent.com/50797982/216764500-24bf11c5-a480-44a5-99c7-853ebaa63744.png) | ![image](https://user-images.githubusercontent.com/50797982/216764489-0fe2cff9-cbb9-4f81-a9de-de3b333a5860.png) |

Typical representation of static and dynamic curves applied to the same color space.
| BT.2446C | Dynamic | BT.2446C | Dynamic | BT.2446C | Dynamic |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216832251-abf05c55-bc97-48e4-97c8-a9b06240f235.png) | ![image](https://user-images.githubusercontent.com/50797982/216832261-93d7dcd4-7588-4086-a4dd-fb48d29c0ade.png) | ![image](https://user-images.githubusercontent.com/50797982/216901529-fa175d65-1fc8-4efe-a5e3-df7d63b4c800.png) | ![image](https://user-images.githubusercontent.com/50797982/216901584-93ffdbae-4f70-4b81-a978-d0fe69e06a39.png) | ![image](https://user-images.githubusercontent.com/50797982/216832312-9a3e1a9f-2dd0-4b28-abd0-b09b5aa45399.png) | ![image](https://user-images.githubusercontent.com/50797982/216832291-fbee6755-b028-4ede-a330-bccf0904a5b3.png) |

### Chroma Correction

This is a part of tone mapping, also known as "highlights desaturate".  
You can set the intensity of it by `set glsl-shader-opts sigma=N`.

Also included crosstalk, it makes the color less chromatic when processing.  
You can set the intensity of it by `set glsl-shader-opts alpha=N`.

In real world, the brighter the color, the less saturated it becomes, and eventually it turns white.

| `sigma=0`                                                                                                       | `sigma=0.2`                                                                                                     | `sigma=1`                                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216247628-8647c010-ff70-488c-bc40-1d57612d1d9f.png) | ![image](https://user-images.githubusercontent.com/50797982/216247654-fc3066a1-098b-4f81-b4c5-a9c8eb6720cd.png) | ![image](https://user-images.githubusercontent.com/50797982/216247675-71c50982-2061-49b1-93b7-87ebe85951d6.png) |

### Gamut mapping

> [!CAUTION]
> Screenshots are outdated and will be updated in the next release.

`clip` is the exact conversion, Others are various forms of compression.

| clip                                                                                                                | jedypod                                                                                                             | bottosson                                                                                                           | lea                                                                                                                 | toru                                                                                                                | false                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/eea8406f-5ad1-4e97-b13a-6dd019b13a70) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/e648e5a1-6bde-4372-9bec-d2da2df6cbbf) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/4bf2c24c-4b76-47d0-b719-fccf663167d5) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/c7f3dd01-c1a6-48a9-a620-cf16a97689da) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/2418d48d-7261-4dd2-89f1-43609fb1b73a) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/fc2dea26-d7c7-4bfc-aa82-b87c54bbd6a9) |
| ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/6cecd47d-7fb6-4b64-9eec-dd00603814d7) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/31883217-11b0-4b68-a3da-39bdfc66479a) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/094d8ac2-7ec2-4cfa-a932-b2a52538cc30) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/2c4f6b1f-b91a-488b-bab6-8d5c83288f8f) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/f8b059c1-aafb-4c5a-ab4c-09999629a68f) | ![image](https://github.com/natural-harmonia-gropius/hdr-toys/assets/50797982/5333a5cd-a446-46f6-96e9-4567cc8b4c3e) |

- The result of `clip` is different from libplacebo, which is due to the black point of BT.1886.  
  I consider that the black point should be set to zero for transcoding and conversion.
