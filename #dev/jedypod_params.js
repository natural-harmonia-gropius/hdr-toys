// Parameters calculator for gamut-mapping/jedypod
// I'm not sure if my process is correct, the reference is below
// https://github.com/jedypod/gamut-compress/blob/master/utilities/CalculateDistance.nk

const { max, abs } = Math;

function multiplyMatrices(A, B) {
  let m = A.length;

  if (!Array.isArray(A[0])) {
    // A is vector, convert to [[a, b, c, ...]]
    A = [A];
  }

  if (!Array.isArray(B[0])) {
    // B is vector, convert to [[a], [b], [c], ...]]
    B = B.map((x) => [x]);
  }

  let p = B[0].length;
  let B_cols = B[0].map((_, i) => B.map((x) => x[i])); // transpose B
  let product = A.map((row) =>
    B_cols.map((col) => {
      let ret = 0;

      if (!Array.isArray(row)) {
        for (let c of col) {
          ret += row * c;
        }

        return ret;
      }

      for (let i = 0; i < row.length; i++) {
        ret += row[i] * (col[i] || 0);
      }

      return ret;
    })
  );

  if (m === 1) {
    product = product[0]; // Avoid [[a, b, c, ...]]
  }

  if (p === 1) {
    return product.map((x) => x[0]); // Avoid [[a], [b], [c], ...]]
  }

  return product;
}

function distance(r, g, b) {
  const ac = max(r, g, b);
  if (ac === 0) return [0, 0, 0];
  return [ac - r, ac - g, ac - b].map((v) => v / abs(ac));
}

function xyY_to_XYZ(x, y, Y) {
  return [(x * Y) / max(y, 1e-6), Y, ((1.0 - x - y) * Y) / max(y, 1e-6)];
}

// XYZ to output color space, BT.709 here
// http://color.support/colorspacecalculator.html
function XYZ_to_RGB(r, g, b) {
  return multiplyMatrices(
    [
      [3.24097, -1.537383, -0.498611],
      [-0.969244, 1.875968, 0.041555],
      [0.05563, -0.203977, 1.056972],
    ],
    [r, g, b]
  );
}

// Chromaticities of input color space, BT.2020 here
// https://en.wikipedia.org/wiki/Rec._2020#System_colorimetry
const limit = [
  [0.708, 0.292, 1.0],
  [0.17, 0.797, 1.0],
  [0.131, 0.046, 1.0],
]
  .map((v) => xyY_to_XYZ(...v))
  .map((v) => XYZ_to_RGB(...v))
  .map((v) => distance(...v))
  .reduce((p, c) => [max(p[0], c[0]), max(p[1], c[1]), max(p[2], c[2])]);

// https://en.wikipedia.org/wiki/ColorChecker#Colors
const threshold = [
  [0.4, 0.35, 10.1],
  [0.377, 0.345, 35.8],
  [0.247, 0.251, 19.3],
  [0.337, 0.422, 13.3],
  [0.265, 0.24, 24.3],
  [0.261, 0.343, 43.1],
  [0.506, 0.407, 30.1],
  [0.211, 0.175, 12.0],
  [0.453, 0.306, 19.8],
  [0.285, 0.202, 6.6],
  [0.38, 0.489, 44.3],
  [0.473, 0.438, 43.1],
  [0.187, 0.129, 6.1],
  [0.305, 0.478, 23.4],
  [0.539, 0.313, 12.0],
  [0.448, 0.47, 59.1],
  [0.364, 0.233, 19.8],
  [0.196, 0.252, 19.8],
  [0.31, 0.316, 90.0],
  [0.31, 0.316, 59.1],
  [0.31, 0.316, 36.2],
  [0.31, 0.316, 19.8],
  [0.31, 0.316, 9.0],
  [0.31, 0.316, 3.1],
]
  .map((v) => [v[0], v[1], v[2] / 100])
  .map((v) => xyY_to_XYZ(...v))
  .map((v) => XYZ_to_RGB(...v))
  .map((v) => distance(...v))
  .reduce((p, c) => [max(p[0], c[0]), max(p[1], c[1]), max(p[2], c[2])]);

console.table({ limit, threshold });
