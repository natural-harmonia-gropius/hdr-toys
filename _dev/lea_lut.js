// import Color from "https://colorjs.io/src/color.js";

const LUT = [];
const LUT_SIZE = 33;

for (let i = 0; i < LUT_SIZE; i++) {
  LUT[i] = [];
  for (let j = 0; j < LUT_SIZE; j++) {
    LUT[i][j] = [];
    for (let k = 0; k < LUT_SIZE; k++) {
      const src = [k, j, i].map((v) => v / (LUT_SIZE - 1));
      const dst = new Color("rec2020-linear", src)
        .to("srgb-linear")
        .toGamut().coords;
      LUT[i][j][k] = dst.join(" ");
    }
  }
}

console.log(LUT.map((y) => y.map((z) => z.join("\n")).join("\n")).join("\n"));
