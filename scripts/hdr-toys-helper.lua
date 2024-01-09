local options = require("mp.options")

local o = {
    timout = 0.2,
    temporal_stable_time = 1 / 3,
}
options.read_options(o)

function clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end

function round(x)
    return math.floor(x + 0.5)
end

function set_L_hdr(v)
    v = round(v)
    v = clamp(v, 0, 10000)
    mp.command("no-osd set glsl-shader-opts L_hdr=" .. v)
end

function set_temporal_stable_frames(v)
    v = round(v)
    v = clamp(v, 0, 120)
    mp.command("no-osd set glsl-shader-opts temporal_stable_frames=" .. v)
end

mp.observe_property("video-out-params", "native", function(_, value)
    if not value then return end

    local sig_peak = value["sig-peak"];
    if not sig_peak or sig_peak == 1 then
        set_L_hdr(1000)
        return
    end

    mp.add_timeout(o.timout, function()
        set_L_hdr(sig_peak * 203)
    end)
end)

mp.observe_property("container-fps", "native", function(_, fps)
    if not fps then return end

    mp.add_timeout(o.timout, function()
        set_temporal_stable_frames(fps * o.temporal_stable_time)
    end)
end)
