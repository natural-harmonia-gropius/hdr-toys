local options = require("mp.options")

local o = {
  temporal_stable_time = 1 / 3,
}
options.read_options(o, _, function() end)

mp.observe_property("container-fps", "native", function (property, value)
  if not value then return end
  value = value * o.temporal_stable_time
  value = math.floor(value + 0.5)
  mp.command("no-osd change-list glsl-shader-opts append temporal_stable_frames=" .. value)
end)
