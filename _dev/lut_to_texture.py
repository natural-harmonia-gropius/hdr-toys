# LUT:
# 1.0 1.0 1.0
# ...
#
# TEX:
# //!TEXTURE lut
# //!SIZE 33 33 33      # same as LUT_3D_SIZE
# //!FORMAT rgba16f
# //!FILTER LINEAR
# put content here

import struct

LUT = "lut.cube"
TEX = "texture.txt"

def flatten(arg):
    if not isinstance(arg, list):  # if not list
        return [arg]
    return [x for sub in arg for x in flatten(sub)]  # recurse and collect


with open(LUT, "r", encoding="utf-8") as f:
    lut = f.read()

data = flatten(
    list(
        map(
            lambda line: list(map(lambda x: float(x), [*line.strip().split(), 1.0])),
            lut.strip().split("\n"),
        )
    )
)

tex = struct.pack(f"<{len(data)}{'f'}", *data).hex()

with open(TEX, "w", encoding="utf-8") as f:
    f.write(tex)
