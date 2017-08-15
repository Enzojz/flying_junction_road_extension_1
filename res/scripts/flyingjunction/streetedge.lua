local func = require "flyingjunction/func"
local streetedge = {}


streetedge.normal = function(tr, t, aligned)
    return function(p)
        return func.with(p, {
            type = "STREET",
            alignTerrain = aligned,
            params = {
                type = t,
                tramTrackType = tr
            },
        })
    end
end


streetedge.bridge = function(tr, t, typeName)
    return function(p)
        return func.with(p, {
            type = "STREET",
            edgeType = "BRIDGE",
            edgeTypeName = typeName,
            params = {
                type = t,
                tramTrackType = tr
            }
        })
    end
end

streetedge.tunnel = function(tr, t)
    return function(p)
        return func.with(p, {
            type = "STREET",
            edgeType = "TUNNEL",
            edgeTypeName = "railroad_old.lua",
            params = {
                type = t,
                tramTrackType = tr
            }
        })
    end
end

streetedge.builder = function(c, t)
    return {
        normal = func.bind(streetedge.normal, c, t, true),
        nonAligned = func.bind(streetedge.normal, c, t, false),
        bridge = func.bind(streetedge.bridge, c, t),
        tunnel = func.bind(streetedge.tunnel, c, t)
    }
end

return streetedge
