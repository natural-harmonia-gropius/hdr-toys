var o = {
  ref_white: 203,
  temporal_stable_time: 1 / 3,
};

var current = {
  L_sdr: 203,
  L_hdr: 1000,
  temporal_stable_frames: 8,
};

var metadata = {
  smpte2086: {
    maxLuminance: undefined,
    minLuminance: undefined,
    displayPrimaryRed: undefined,
    displayPrimaryGreen: undefined,
    displayPrimaryBlue: undefined,
    whitePoint: undefined,
  },
  cta861_3: {
    maxContentLightLevel: undefined,
    maxFrameAverageLightLevel: undefined,
  },
  hdr10plus: {
    maxR: undefined,
    maxG: undefined,
    maxB: undefined,
  },
  detect: {
    max: undefined,
    avg: undefined,
  },
};

function set_L_sdr(x) {
  x = Math.min(Math.max(x, 10), 1000);

  if (x === current.L_sdr) return;
  mp.command("no-osd set glsl-shader-opts L_sdr=" + x);
  current.L_sdr = x;
}

function set_L_hdr(x) {
  x = Math.min(Math.max(x, current.L_sdr + 1), 10000);

  if (x === current.L_hdr) return;
  mp.command("no-osd set glsl-shader-opts L_hdr=" + x);
  current.L_hdr = x;
}

function set_temporal_stable_frames(x) {
  x = x * o.temporal_stable_time;
  x = Math.round(x);
  x = Math.min(Math.max(x, 0), 120);

  mp.command("no-osd set glsl-shader-opts temporal_stable_frames=" + x);
  current.temporal_stable_frames = x;
}

mp.observe_property("video-out-params", "native", function (property, value) {
  if (!value) return;

  if (!value["max-luma"]) {
    // SDR
    return;
  }

  metadata.smpte2086.maxLuminance = value["max-luma"];
  metadata.smpte2086.minLuminance = value["min-luma"];
  metadata.cta861_3.maxContentLightLevel = value["max-cll"];
  metadata.cta861_3.maxFrameAverageLightLevel = value["max-fall"];
  metadata.hdr10plus.maxR = value["scene-max-r"];
  metadata.hdr10plus.maxG = value["scene-max-g"];
  metadata.hdr10plus.maxB = value["scene-max-b"];
  metadata.detect.max = value["max-pq-y"];
  metadata.detect.avg = value["avg-pq-y"];

  set_L_hdr(
    Math.max(
      metadata.smpte2086.maxLuminance,
      metadata.cta861_3.maxContentLightLevel
    )
  );
});

mp.observe_property("container-fps", "native", function (property, value) {
  if (!value) return;

  set_temporal_stable_frames(value);
});
