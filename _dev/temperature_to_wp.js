// https://github.com/colour-science/colour/blob/develop/colour/temperature/cie_d.py#L120

const K = 6504.38938305;

function CCT_to_xy_CIE_D(CCT) {
  if (4000 > CCT || CCT > 25000)
    throw new Error(
      "Correlated colour temperature must be in domain, [4000, 25000], unpredictable results may occur!"
    );

  const CCT_2 = CCT ** 2;
  const CCT_3 = CCT ** 3;

  const x =
    CCT <= 7000
      ? (0.09911 * 10 ** 3) / CCT +
        (2.9678 * 10 ** 6) / CCT_2 +
        (-4.607 * 10 ** 9) / CCT_3 +
        0.244063
      : (0.24748 * 10 ** 3) / CCT +
        (1.9018 * 10 ** 6) / CCT_2 +
        (-2.0064 * 10 ** 9) / CCT_3 +
        0.23704;

  // daylight_locus_function
  const y = -3.0 * x ** 2 + 2.87 * x - 0.275;

  return [x, y];
}

console.log(CCT_to_xy_CIE_D(K));
