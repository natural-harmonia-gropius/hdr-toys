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

function xyY_to_XYZ(x, y, Y) {
  const X = (x * Y) / max(y, 1e-6);
  const Z = ((1.0 - x - y) * Y) / max(y, 1e-6);

  return [X, Y, Z];
}

function XYZ_to_BT2020(X, Y, Z) {
  const M = [
    [1.716651187971268, -0.355670783776392, -0.25336628137366],
    [-0.666684351832489, 1.616481236634939, 0.0157685458139111],
    [0.017639857445311, -0.042770613257809, 0.942103121235474],
  ];
  return multiplyMatrices(M, [X, Y, Z]);
}

function BT2020_to_BT709(r, g, b) {
  const M = [
    [1.6604910021084354, -0.5876411387885495, -0.07284986331988474],
    [-0.12455047452159074, 1.1328998971259596, -0.008349422604369515],
    [-0.01815076335490526, -0.10057889800800737, 1.118729661362913],
  ];
  return multiplyMatrices(M, [r, g, b]);
}

function distance(r, g, b) {
  const ac = max(r, g, b);

  if (ac === 0) {
    return [0, 0, 0];
  }

  const d = [ac - r / abs(ac), ac - g / abs(ac), ac - b / abs(ac)];

  return d;
}

const limit = [
  [1, 0, 0],
  [0, 1, 0],
  [0, 0, 1],
]
  .map((v) => BT2020_to_BT709(...v))
  .map((v) => distance(...v))
  .reduce((p, c) => [max(p[0], c[0]), max(p[1], c[1]), max(p[2], c[2])]);

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
  .map((v) => XYZ_to_BT2020(...v))
  .map((v) => BT2020_to_BT709(...v))
  .map((v) => distance(...v))
  .reduce((p, c) => [max(p[0], c[0]), max(p[1], c[1]), max(p[2], c[2])]);

console.table({ threshold, limit });
