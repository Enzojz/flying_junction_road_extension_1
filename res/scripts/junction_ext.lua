local paramsutil = require "paramsutil"
local func = require "flyingjunction/func"
local coor = require "flyingjunction/coor"
local trackEdge = require "flyingjunction/trackedge"
local streetEdge = require "flyingjunction/streetedge"
local pipe = require "flyingjunction/pipe"
local station = require "flyingjunction/stationlib"
local junction = require "junction"
local jA = require "junction_assoc"
local jM = require "junction_main"

local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local listDegree = {5, 10, 20, 30, 40, 50, 60, 70, 80}
local rList = {junction.infi * 0.001, 5, 3.5, 2, 1, 4 / 5, 2 / 3, 3 / 5, 1 / 2, 1 / 3, 1 / 4, 1 / 5, 1 / 6, 1 / 8, 1 / 10, 1 / 20}

local trSlopeList = {15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 80, 90, 100}
local slopeList = {0, 10, 20, 25, 30, 35, 40, 50, 60}
local heightList = {0, 1 / 4, 1 / 3, 1 / 2, 2 / 3, 3 / 4, 1, 1.1, 1.2, 1.25, 1.5}
local tunnelHeightList = {11, 10, 9.5, 8.7}
local lengthPercentList = {1, 4 / 5, 3 / 4, 3 / 5, 1 / 2, 2 / 5, 1 / 4, 1 / 5, 1 / 10, 1 / 20}

local nbTracksList = {1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14}

local trackList = {"standard.lua", "high_speed.lua"}
local trackWidthList = {5, 5}
local trackType = pipe.exec * function()
    local list = {
        {
            key = "trackType",
            name = _("Track type"),
            values = {_("Standard"), _("High-speed")},
            yearFrom = 1925,
            yearTo = 0
        },
        {
            key = "catenary",
            name = _("Catenary"),
            values = {_("No"), _("Yes")},
            defaultIndex = 1,
            yearFrom = 1910,
            yearTo = 0
        }
    }
    if (commonapi and commonapi.uiparameter) then
        commonapi.uiparameter.modifyTrackCatenary(list, {selectionlist = trackList})
        trackWidthList = func.map(trackList, function(e) return commonapi.repos.track.getByName(e).data.trackDistance end)
    end
    
    return pipe.new * list
end

local pi = math.pi

local function generateStructure(lowerGroup, upperGroup, mDepth, models)
    local function mPlace(fitModel, arcL, arcR, rad1, rad2)
        local size = {
            lt = arcL:pt(rad1):withZ(0),
            lb = arcL:pt(rad2):withZ(0),
            rt = arcR:pt(rad1):withZ(0),
            rb = arcR:pt(rad2):withZ(0)
        }
        return fitModel(size) * mDepth
    end
    local mPlaceD = function()
        return coor.I()
    end
    local function mPlaceR(fitModel, arcL, arcR, rad1, rad2)
        return coor.transZ(-1.5) * mPlace(fitModel, arcL, arcR, rad1, rad2)
    end
    
    local makeExtWall = junction.makeFn(models.mSidePillar, junction.fitModel2D(0.5, 5), 0.5, mPlaceD)
    local makeExtWallFence = junction.makeFn(models.mRoofFenceS, junction.fitModel2D(0.5, 5), 0.5, mPlaceD)
    local makeWall = junction.makeFn(models.mSidePillar, junction.fitModel2D(0.5, 5), 0.5, mPlace)
    local makeRoof = junction.makeFn(models.mRoof, junction.fitModel2D(5, 5), 5, mPlace)
    local makeSideFence = junction.makeFn(models.mRoofFenceS, junction.fitModel2D(0.5, 5), 0.5, mPlace)
    local makeRoofFence = junction.makeFn(models.mRoofFenceS, junction.fitModel2D(0.5, 5), 0.5, mPlaceR)
    
    local walls = lowerGroup.simpleWalls
    
    local upperFences = func.map(upperGroup.tracks, function(t)
        local inner = t + (-2.5)
        local outer = t + 2.5
        local diff = (t.inf > t.sup and 0.5 or -0.5) / t.r
        return {
            station.newModel(models.mSidePillar.."_tl.mdl", coor.rotZ(pi * 0.5), mPlace(junction.fitModel2D(5, 0.5)(false, true), inner, outer, t.inf, t.inf - diff)),
            station.newModel(models.mSidePillar.."_br.mdl", coor.rotZ(pi * 0.5), mPlace(junction.fitModel2D(5, 0.5)(true, false), inner, outer, t.inf, t.inf - diff)),
            station.newModel(models.mSidePillar.."_tl.mdl", coor.rotZ(pi * 0.5), mPlace(junction.fitModel2D(5, 0.5)(false, true), inner, outer, t.sup, t.sup + diff)),
            station.newModel(models.mSidePillar.."_br.mdl", coor.rotZ(pi * 0.5), mPlace(junction.fitModel2D(5, 0.5)(true, false), inner, outer, t.sup, t.sup + diff))
        }
    end)
    
    return {
        {
            fixed = pipe.new
            + func.mapFlatten(walls, function(w) return makeWall(w)[1] end)
            + func.mapFlatten(upperGroup.tracks, function(t) return makeRoof(t)[1] end)
            + func.mapFlatten(upperGroup.simpleWalls, function(t) return makeSideFence(t)[1] end)
            + func.mapFlatten(upperGroup.simpleWalls, function(t) return makeRoofFence(t)[1] end)
            ,
            upper = pipe.new
            + makeSideFence(upperGroup.walls[2])[1]
            + makeWall(upperGroup.walls[2])[1]
            + func.mapFlatten(upperFences, pipe.range(1, 2))
            ,
            lower = pipe.new
            + makeExtWall(lowerGroup.extSimpleWalls[1])[1]
            + makeExtWallFence(lowerGroup.extSimpleWalls[1])[1],
        }
        ,
        {
            fixed = pipe.new
            + func.mapFlatten(walls, function(w) return makeWall(w)[2] end)
            + func.mapFlatten(upperGroup.tracks, function(t) return makeRoof(t)[2] end)
            + func.mapFlatten(upperGroup.simpleWalls, function(t) return makeSideFence(t)[2] end)
            + func.mapFlatten(upperGroup.simpleWalls, function(t) return makeRoofFence(t)[2] end)
            ,
            upper = pipe.new
            + makeSideFence(upperGroup.walls[1])[2]
            + makeWall(upperGroup.walls[1])[2]
            + func.mapFlatten(upperFences, pipe.range(3, 4))
            ,
            lower = pipe.new
            + makeExtWall(lowerGroup.extSimpleWalls[2])[2]
            + makeExtWallFence(lowerGroup.extSimpleWalls[2])[2]
        }
    }
end


local function params(paramFilter)
    local sp = "·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·:·\n"
    return (pipe.new * trackType +
        {
            {
                key = "nbTracks",
                name = _("Number of tracks"),
                values = func.map(nbTracksList, tostring),
                defaultIndex = 1
            },
            {
                key = "nbPerGroup",
                name = _("Tracks per group"),
                values = {_("1"), _("2"), _("All")},
                defaultIndex = 1
            },
            {
                key = "streetUsage",
                name = sp,
                values = {_("Street"), _("Route")},
                defaultIndex = 1
            },
            {
                key = "streetType",
                name = _("Road Type"),
                values = {"S", "M", "L", "XL"},
                defaultIndex = 2
            },
            paramsutil.makeTramTrackParam1(),
            paramsutil.makeTramTrackParam2(),
            {
                key = "isRoadSp",
                name = _("Sepeated road lanes"),
                values = {_("No"), _("Yes")},
                defaultIndex = 0
            },
            {
                key = "roadSlopeFactor",
                name = _("Road slope factor"),
                values = func.map({1, 2, 3, 4, 5}, tostring),
                defaultIndex = 3
            },
            {
                key = "layout",
                name = sp.._("Layout"),
                values = {_("Rail") .. "/" .. _("Road"), _("Road") .. "/" .. _("Rail"), _("Road") .. "/" .. _("Road")},
                defaultIndex = 0
            },
            {
                key = "xDegDec",
                name = _("Crossing angles"),
                values = {_("5"), _("10"), _("20"), _("30"), _("40"), _("50"), _("60"), _("70"), _("80"), },
                defaultIndex = 6
            },
            {
                key = "xDegUni",
                name = "+",
                values = func.seqMap({0, 9}, tostring),
            },
            {
                key = "sLower",
                name = sp,
                values = {"+", "-"},
                defaultIndex = 0
            },
            {
                key = "rLower",
                name = _("Radius of lower level"),
                values = pipe.from("∞") + func.map(func.range(rList, 2, #rList), function(r) return tostring(floor(r * 1000 + 0.5)) end),
                defaultIndex = 0
            },
            {
                key = "sUpper",
                name = sp,
                values = {"+", "-"},
                defaultIndex = 0
            },
            {
                key = "rUpper",
                name = _("Radius of upper level"),
                values = pipe.from("∞") + func.map(func.range(rList, 2, #rList), function(r) return tostring(floor(r * 1000 + 0.5)) end),
                defaultIndex = 0
            },
            {
                key = "transitionA",
                name = sp .. "\n" .. _("Transition A"),
                values = {_("Both"), _("Lower"), _("Upper"), _("None")},
                defaultIndex = 0
            },
            {
                key = "trSlopeA",
                name = _("Slope") .. " (‰)",
                values = func.map(trSlopeList, tostring),
                defaultIndex = #trSlopeList * 0.5
            },
            {
                key = "trSRadiusA",
                name = nil,
                values = {"+", "-"},
                defaultIndex = 0
            },
            {
                key = "trRadiusA",
                name = _("Radius") .. "(m)",
                values = pipe.from("∞") + func.map(func.range(rList, 2, #rList), function(r) return tostring(floor(r * 1000 + 0.5)) end),
                defaultIndex = 0
            },
            {
                key = "trLengthUpperA",
                name = _("Upper level length") .. " (%)",
                values = func.map(lengthPercentList, function(l) return tostring(l * 100) end),
                defaultIndex = 0
            },
            {
                key = "trLengthLowerA",
                name = _("Lower level length") .. " (%)",
                values = func.map(lengthPercentList, function(l) return tostring(l * 100) end),
                defaultIndex = 0
            },
            {
                key = "typeSlopeA",
                name = _("Form"),
                values = {_("Bridge"), _("Terra"), _("Solid")},
                defaultIndex = 1
            },
            {
                key = "transitionB",
                name = sp .. "\n" .. _("Transition B"),
                values = {_("Both"), _("Lower"), _("Upper"), _("None")},
                defaultIndex = 0
            },
            {
                key = "trSlopeB",
                name = _("Slope") .. " (‰)",
                values = func.map(trSlopeList, tostring),
                defaultIndex = #trSlopeList * 0.5
            },
            {
                key = "trSRadiusB",
                name = nil,
                values = {"+", "-"},
                defaultIndex = 0
            },
            {
                key = "trRadiusB",
                name = _("Radius") .. "(m)",
                values = pipe.from("∞") + func.map(func.range(rList, 2, #rList), function(r) return tostring(floor(r * 1000 + 0.5)) end),
                defaultIndex = 0
            },
            {
                key = "trLengthUpperB",
                name = _("Upper level length") .. " (%)",
                values = func.map(lengthPercentList, function(l) return tostring(l * 100) end),
                defaultIndex = 0
            },
            {
                key = "trLengthLowerB",
                name = _("Lower level length") .. " (%)",
                values = func.map(lengthPercentList, function(l) return tostring(l * 100) end),
                defaultIndex = 0
            },
            {
                key = "typeSlopeB",
                name = _("Form"),
                values = {_("Bridge"), _("Terra"), _("Solid")},
                defaultIndex = 1
            },
            {
                key = "bridgeForm",
                name = sp.."\n" .. _("Structure Form"),
                values = {_("Simple"), _("Flying junction")},
                defaultIndex = 1,
            },
            {
                key = "isMir",
                name = _("Mirrored"),
                values = {_("No"), _("Yes")},
                defaultIndex = 0
            },
            {
                key = "slopeSign",
                name = sp,
                values = {"+", "-"},
                defaultIndex = 0
            },
            {
                key = "slope",
                name = _("General Slope") .. " (‰)",
                values = func.map(slopeList, tostring),
                defaultIndex = 0
            },
            {
                key = "slopeLevel",
                name = _("Axis"),
                values = {_("Lower"), _("Upper"), _("Common")},
                defaultIndex = 0
            },
            {
                key = "heightTunnel",
                name = sp .. "\n" .. _("Tunnel Height") .. " (m)",
                values = func.map(tunnelHeightList, tostring),
                defaultIndex = #tunnelHeightList - 2
            },
            {
                key = "height",
                name = _("Altitude Adjustment"),
                values = func.map(heightList, function(h) return tostring(ceil(h * 100)) .. "%" end),
                defaultIndex = 6
            }
        })
        * pipe.filter(function(p) return not func.contains(paramFilter, p.key) end)

end

local function defaultParams(param, fParams)
    local function limiter(d, u)
        return function(v) return v and v < u and v or d end
    end
    
    param.trackType = param.trackType or 0
    param.catenary = param.catenary or 0

    func.forEach(
        func.filter(params({}), function(p) return p.key ~= "tramTrack" end),
        function(i)param[i.key] = limiter(i.defaultIndex or 0, #i.values)(param[i.key]) end)
        
    fParams(param)
end

local updateFn = function(fParams, models, streetConfig)
    return function(params)
        
            defaultParams(params, fParams)
            
            local deg = listDegree[params.xDegDec + 1] + params.xDegUni
            local rad = math.rad(deg)
            
            local trackType = trackList[params.trackType + 1]
            local catenary = params.catenary == 1 -- and catenary
            local streetGroup = streetConfig[params.streetUsage == 0 and "street" or "country"]
            local streetType = streetGroup.type[params.streetType + 1]
            local streetWidth = streetGroup.width[params.streetType + 1]
            local tramType = ({"NO", "YES", "ELECTRIC"})[params.tramTrack + 1]
            
            local tunnelHeight = tunnelHeightList[params.heightTunnel + 1]
            local heightFactor = heightList[params.height + 1]
            local depth = ((heightFactor > 1 and 1 or heightFactor) - 1) * tunnelHeight
            local mDepth = coor.transZ(depth)
            local extraZ = heightFactor > 1 and ((heightFactor - 1) * tunnelHeight) or 0
            local mTunnelZ = coor.transZ(tunnelHeight)
            
            local trackBuilder = trackEdge.builder(catenary, trackType)
            local streetBuilder = streetEdge.builder(tramType, streetType)
            
            local isUpperRoad = func.contains({1, 2}, params.layout)
            local isLowerRoad = func.contains({0, 2}, params.layout)
            
            local nbTracks = nbTracksList[params.nbTracks + 1]

            local nbPerGroup = ({1, 2, nbTracks})[params.nbPerGroup + 1]

            local TLowerTracks = isLowerRoad and streetBuilder.nonAligned() or trackBuilder.nonAligned()
            local TUpperTracks = isUpperRoad and streetBuilder.nonAligned() or trackBuilder.nonAligned()
            local TUpperExtTracks = isUpperRoad and streetBuilder.bridge(models.bridgeType) or trackBuilder.bridge(models.bridgeType)
            local retriveR = function(param) return rList[param + 1] * 1000 end
            
            local info = {
                A = {
                    lower = {
                        nbTracks = isLowerRoad and 1 or nbTracks,
                        r = retriveR(params.rLower) * params.fRLowerA * (params.sLower == 1 and 1 or -1) * (params.type == 3 and -1 or 1),
                        rFactor = params.fRLowerA * (params.sLower == 1 and 1 or -1) * (params.type == 3 and -1 or 1),
                        rad = 0,
                        used = func.contains({0, 1}, params.transitionA),
                        isBridge = false,
                        isTerra = false,
                        extR = (params.trSRadiusA == 0 and 1 or -1) * retriveR(params.trRadiusA)
                    },
                    upper = {
                        nbTracks = isUpperRoad and 1 or nbTracks,
                        r = retriveR(params.rUpper) * params.fRUpperA * (params.sUpper == 0 and 1 or -1),
                        rFactor = params.fRUpperA * (params.sUpper == 0 and 1 or -1),
                        rad = rad,
                        used = func.contains({0, 2}, params.transitionA),
                        isBridge = params.typeSlopeA == 0 or not func.contains({0, 2}, params.transitionA),
                        isTerra = params.typeSlopeA == 1 and func.contains({0, 2}, params.transitionA) and params.type ~= 2,
                        extR = (params.trSRadiusA == 0 and 1 or -1) * retriveR(params.trRadiusA)
                    }
                },
                B = {
                    lower = {
                        nbTracks = isLowerRoad and 1 or nbTracks,
                        r = retriveR(params.rLower) * params.fRLowerB * (params.sLower == 1 and 1 or -1) * (params.type == 3 and -1 or 1),
                        rFactor = params.fRLowerB * (params.sLower == 1 and 1 or -1) * (params.type == 3 and -1 or 1),
                        rad = 0,
                        used = func.contains({0, 1}, params.transitionB),
                        isBridge = false,
                        isTerra = false,
                        extR = (params.trSRadiusB == 0 and 1 or -1) * retriveR(params.trRadiusB)
                    },
                    upper = {
                        nbTracks = isUpperRoad and 1 or nbTracks,
                        r = retriveR(params.rUpper) * params.fRUpperB * (params.sUpper == 0 and 1 or -1),
                        rFactor = params.fRUpperB * (params.sUpper == 0 and 1 or -1),
                        rad = rad,
                        used = func.contains({0, 2}, params.transitionB),
                        isBridge = params.typeSlopeB == 0 or not func.contains({0, 2}, params.transitionB),
                        isTerra = params.typeSlopeB == 1 and func.contains({0, 2}, params.transitionB) and params.type ~= 2,
                        extR = (params.trSRadiusB == 0 and 1 or -1) * retriveR(params.trRadiusB)
                    }
                }
            }
            
            local offsets = {
                lower = junction.buildCoors(info.A.lower.nbTracks, isLowerRoad and 1 or nbPerGroup, isLowerRoad and { trackWidth = streetWidth, wallWidth = 0.5 } or nil),
                upper = junction.buildCoors(info.A.upper.nbTracks, info.A.upper.nbTracks, isUpperRoad and { trackWidth = streetWidth, wallWidth = 0.5 } or nil)
            }
            
            local group = {
                A = jM.trackGroup(info.A, offsets),
                B = jM.trackGroup(info.B, offsets)
            }
            
            local structureOffsets = {
                lower = isLowerRoad
                and {
                    tracks = streetGroup.offset[params.isRoadSp + 1][params.streetType + 1],
                    walls = params.isRoadSp == 0 and {-0.25 - streetWidth * 0.5, 0.25 + streetWidth * 0.5} or {-0.25 - streetWidth * 0.5, 0, 0.25 + streetWidth * 0.5}
                } or offsets.lower,
                upper = isUpperRoad
                and {
                    tracks = streetGroup.offset[1][params.streetType + 1],
                    walls = {-0.25 - streetWidth * 0.5, 0.25 + streetWidth * 0.5}
                } or offsets.upper,
            }
            
            local structureGroup = {
                A = jM.trackGroup(info.A, structureOffsets),
                B = jM.trackGroup(info.B, structureOffsets)
            }
            
            local ext, preparedExt = (function()
                local extEndList = {A = "inf", B = "sup"}
                local extConfig = {
                    straight = function(equalLength)
                        return function(part, level, type)
                            return {
                                group = group[part].ext[level][type][extEndList[part]],
                                models = models,
                                radFn = function(g) return g.rad end,
                                rFn = function(g) return g.r end,
                                guidelineFn = function(g) return g.guideline end,
                                part = part,
                                level = level,
                                equalLength = equalLength or false,
                            } end
                    end,
                    curve = function(equalLength)
                        return function(part, level, type) return {
                            group = group[part][level][type],
                            models = models,
                            radFn = function(_) return group[part][level].tracks[1][extEndList[part]] end,
                            rFn = function(g) return info[part][level].rFactor * g.r end,
                            guidelineFn = function(g) return g end,
                            part = part,
                            level = level,
                            equalLength = equalLength or false,
                        } end
                    end
                }
                
                local extProtos = function(type) return {
                    upper = {
                        A = pipe.from("A", "upper", type) * (func.contains({3, 1}, params.type) and extConfig.curve() or extConfig.straight(true)),
                        B = pipe.from("B", "upper", type) * (func.contains({1}, params.type) and extConfig.curve() or extConfig.straight(true))
                    },
                    lower = {
                        A = pipe.from("A", "lower", type) * (func.contains({3, 1}, params.type) and extConfig.curve() or extConfig.straight(true)),
                        B = pipe.from("B", "lower", type) * (func.contains({1}, params.type) and extConfig.curve() or extConfig.straight(true))
                    },
                    info = {
                        height = depth,
                        tunnelHeight = tunnelHeight,
                        slope = {
                            A = trSlopeList[params.trSlopeA + 1] * 0.001,
                            B = trSlopeList[params.trSlopeB + 1] * 0.001
                        },
                        vRadius = {
                            lower = isLowerRoad and 75 or 300,
                            upper = isUpperRoad and 75 or 300,
                        },
                        slopeFactor = {
                            lower = isLowerRoad and (params.roadSlopeFactor + 1) or 1,
                            upper = isUpperRoad and (params.roadSlopeFactor + 1) or 1,
                        },
                        frac = {
                            lower = {
                                A = heightFactor >= 1 and 1 or lengthPercentList[params.trLengthLowerA + 1],
                                B = heightFactor >= 1 and 1 or lengthPercentList[params.trLengthLowerB + 1]
                            },
                            upper = {
                                A = heightFactor == 0 and 1 or lengthPercentList[params.trLengthUpperA + 1],
                                B = heightFactor == 0 and 1 or lengthPercentList[params.trLengthUpperB + 1]
                            }
                        }
                    }
                }
                end
                
                local preparedExt = {
                    tracks = jM.retriveExt(extProtos("tracks")),
                    walls = jM.retriveExt(extProtos("walls"))
                }
                
                return {
                    edges = jM.retriveX(jA.retriveTracks, preparedExt.tracks),
                    polys = {
                        upper = {
                            A = (isUpperRoad and jA.retrivePolys(4, streetWidth * 0.5 + 1) or jA.retrivePolys())(preparedExt.tracks.upper.A),
                            B = (isUpperRoad and jA.retrivePolys(4, streetWidth * 0.5 + 1) or jA.retrivePolys())(preparedExt.tracks.upper.B)
                        },
                        lower = {
                            A = (isLowerRoad and jA.retrivePolys(4, streetWidth * 0.5 + 1) or jA.retrivePolys())(preparedExt.tracks.lower.A),
                            B = (isLowerRoad and jA.retrivePolys(4, streetWidth * 0.5 + 1) or jA.retrivePolys())(preparedExt.tracks.lower.B)
                        }
                    },
                    surface = jM.retriveX(jA.retriveTrackSurfaces, preparedExt.tracks),
                    walls = jM.retriveX(jA.retriveWalls, preparedExt.walls)
                }, preparedExt
            end)()
            
            local trackEdges = {
                lower = jM.generateTrackGroups(group.A.lower.tracks, group.B.lower.tracks, {mpt = mDepth, mvec = coor.I()}),
                upper = jM.generateTrackGroups(group.A.upper.tracks, group.B.upper.tracks, {mpt = mTunnelZ * mDepth, mvec = coor.I()})
            }
            
            local upperPolys = {
                A = junction.generatePolyArc(group.A.upper.tracks, "inf", "mid")(0, isUpperRoad and streetWidth * 0.5 + 1 or 3.5),
                B = junction.generatePolyArc(group.B.upper.tracks, "mid", "sup")(0, isUpperRoad and streetWidth * 0.5 + 1 or 3.5)
            }
            
            local lowerPolys = {
                A = junction.generatePolyArc(group.A.lower.tracks, "inf", "mid")(4, isLowerRoad and streetWidth * 0.5 + 1or 3.5),
                B = junction.generatePolyArc(group.B.lower.tracks, "mid", "sup")(4, isLowerRoad and streetWidth * 0.5 + 1or 3.5)
            }
            
            local function selectEdge(level)
                return (pipe.new
                    + (
                    info.A[level].used
                    and {
                        ext.edges[level].A.inf,
                        ext.edges[level].A.main
                    }
                    or {trackEdges[level].inf}
                    )
                    + {trackEdges[level].main}
                    + (
                    info.B[level].used
                    and {
                        ext.edges[level].B.main,
                        ext.edges[level].B.sup
                    }
                    or {trackEdges[level].sup}
                    ))
                    * station.fusionEdges
                    ,
                    pipe.new
                    + (info.A[level].used and (info.A[level].isBridge and {true, true} or {false, false}) or {true})
                    + {false}
                    + (info.B[level].used and (info.B[level].isBridge and {true, true} or {false, false}) or {true})
            end
            
            local lowerEdges, _ = selectEdge("lower")
            local upperEdges, upperBridges = selectEdge("upper")
            
            local bridgeEdges = upperEdges
                * pipe.zip(upperBridges, {"e", "b"})
                * pipe.filter(function(e) return e.b end)
                * pipe.map(pipe.select("e"))
            
            local solidEdges = upperEdges
                * pipe.zip(upperBridges, {"e", "b"})
                * pipe.filter(function(e) return not e.b end)
                * pipe.map(pipe.select("e"))
            
            local edges = pipe.new
                / (solidEdges * pipe.map(station.mergeEdges) * station.prepareEdges * TUpperTracks)
                / (bridgeEdges * pipe.map(station.mergeEdges) * station.prepareEdges * TUpperExtTracks)
                / (lowerEdges * pipe.map(station.mergeEdges) * station.prepareEdges * TLowerTracks)

            local structureGen = params.bridgeForm == 0 and generateStructure or jM.generateStructure

            local structure = {
                A = structureGen(structureGroup.A.lower, structureGroup.A.upper, mTunnelZ * mDepth, models)[1],
                B = structureGen(structureGroup.B.lower, structureGroup.B.upper, mTunnelZ * mDepth, models)[2]
            }
            
            local innerWalls = params.bridgeForm == 0 and "simpleWalls" or "walls"

            local slopeWallModels = jM.slopeWalls(
                info,
                models,
                tunnelHeight * heightFactor,
                preparedExt.walls.lower.A,
                isLowerRoad and {structureGroup.A.lower[innerWalls][1], structureGroup.A.lower[innerWalls][#structureGroup.A.lower[innerWalls]]} or group.A.lower[innerWalls],
                preparedExt.walls.lower.B,
                isLowerRoad and {structureGroup.B.lower[innerWalls][1], structureGroup.B.lower[innerWalls][#structureGroup.B.lower[innerWalls]]} or group.B.lower[innerWalls],
                preparedExt.walls.upper.A[1],
                preparedExt.walls.upper.B[#preparedExt.walls.upper.B]
            )

            local uPolys = function(part)
                local i = info[part].upper
                local polySet = ext.polys.upper[part]
                return (not i.used or i.isBridge)
                    and {}
                    or (
                    i.isTerra
                    and {
                        equal = station.projectPolys(coor.I())(polySet.trackPolys)
                    }
                    or {
                        greater = station.projectPolys(coor.I())(polySet.polys),
                        less = station.projectPolys(coor.I())(polySet.trackPolys)
                    }
            )
            end
            
            local slopeWallArcs = pipe.new
                / func.map(info.A.upper.isTerra and preparedExt.tracks.lower.A or {},
                function(w)
                    return {
                        lower = w.guidelines[2]:withLimits({inf = w.guidelines[1]:extendLimits(4).inf}),
                        upper = preparedExt.walls.upper.A[1].guidelines[1],
                        fz = preparedExt.walls.upper.A[1].fn.fz,
                        from = "sup", to = "inf"
                    }
                end)
                / func.map(info.B.upper.isTerra and preparedExt.tracks.lower.B or {},
                function(w)
                    return {
                        lower = w.guidelines[1]:withLimits({sup = w.guidelines[2]:extendLimits(4).sup}),
                        upper = preparedExt.walls.upper.B[#preparedExt.walls.upper.B].guidelines[1],
                        fz = preparedExt.walls.upper.B[#preparedExt.walls.upper.B].fn.fz,
                        from = "inf", to = "sup"
                    }
                end)
                * pipe.map(pipe.map(function(sw)
                    local arcExt = isLowerRoad and {
                        sw.lower + (streetWidth * 0.5),
                        sw.lower + (streetWidth * 0.25),
                        sw.lower + (-streetWidth * 0.5),
                        sw.lower + (-streetWidth * 0.25),
                    } or {
                        sw.lower + 2.5,
                        sw.lower + (-2.5),
                    }

                    local loc = func.min(
                        func.map(arcExt, function(a) return jM.detectSlopeIntersection(a, sw.upper, sw.fz, a[sw.from], a[sw.to] - a[sw.from]) end),
                        function(l, r) return abs(l - sw.lower[sw.to]) < abs(r - sw.lower[sw.to]) end)

                    return sw.lower:withLimits({
                        [sw.from] = loc,
                        [sw.to] = sw[sw.to],
                    })
                end
                ))
                * pipe.map(pipe.map(function(ar) return junction.generatePolyArc({ar, ar}, "inf", "sup")(0, isLowerRoad and streetWidth * 0.5 or 2.5) end))
                * function(ls) return {A = func.flatten(ls[1]), B = func.flatten(ls[2])} end
                        
            local lPolys = function(part)
                local i = info[part].lower
                local polySet = ext.polys.lower[part]
                return (not i.used)
                    and {}
                    or {
                        less = station.projectPolys(coor.I())(info[part].upper.isTerra and slopeWallArcs[part] or polySet.polys),
                        slot = station.projectPolys(coor.I())(polySet.trackPolys),
                        greater = station.projectPolys(coor.I())(polySet.trackPolys)
                    }
            end
            
            local uXPolys = {
                equal = pipe.new
                + ((info.A.upper.isTerra or heightFactor == 0) and station.projectPolys(mTunnelZ * mDepth)(upperPolys.A) or {})
                + ((info.B.upper.isTerra or heightFactor == 0) and station.projectPolys(mTunnelZ * mDepth)(upperPolys.B) or {})
                ,
                less = pipe.new
                + ((not info.A.upper.isTerra and heightFactor ~= 0) and station.projectPolys(mTunnelZ * mDepth)(upperPolys.A) or {})
                + ((not info.B.upper.isTerra and heightFactor ~= 0) and station.projectPolys(mTunnelZ * mDepth)(upperPolys.B) or {})
                ,
                greater = pipe.new + (info.A.upper.isTerra and {} or station.projectPolys(mDepth)(upperPolys.A))
                + (info.B.upper.isTerra and {} or station.projectPolys(mDepth)(upperPolys.B))
            }
            
            local lXPolys = {
                less = station.projectPolys(coor.I())(info.A.upper.isTerra and {} or lowerPolys.A, info.B.upper.isTerra and {} or lowerPolys.B),
                slot = station.projectPolys(mDepth * coor.transZ(-0.2))(lowerPolys.A, lowerPolys.B),
                greater = station.projectPolys(mDepth)(lowerPolys.A, lowerPolys.B)
            }
            

            local function withIfNotBridge(level, part)
                return function(c)
                    return (info[part][level].used and not info[part][level].isBridge) and c or {}
                end
            end
            
            local function withIfSolid(level, part)
                return function(c)
                    return (info[part][level].used and not info[part][level].isTerra and not info[part][level].isBridge) and c or {}
                end
            end
            

            local result = {
                edgeLists = edges,
                models = pipe.new
                + structure.A.fixed
                + structure.B.fixed
                + withIfSolid("upper", "A")(ext.surface.upper.A)
                + withIfSolid("upper", "B")(ext.surface.upper.B)
                + (heightFactor > 0
                and pipe.new
                + structure.A.upper
                + structure.B.upper
                + withIfSolid("upper", "A")(ext.walls.upper.A * pipe.flatten())
                + withIfSolid("upper", "B")(ext.walls.upper.B * pipe.flatten())
                or {}
                )
                + (heightFactor < 1
                and pipe.new
                + structure.A.lower
                + structure.B.lower
                + withIfNotBridge("lower", "A")(ext.walls.lower.A[1])
                + withIfNotBridge("lower", "A")(ext.walls.lower.A[#ext.walls.lower.A])
                + withIfNotBridge("lower", "B")(ext.walls.lower.B[1])
                + withIfNotBridge("lower", "B")(ext.walls.lower.B[#ext.walls.lower.B])
                or {})
                + slopeWallModels
                ,
                terrainAlignmentLists = station.mergePoly(uXPolys, uPolys("A"), uPolys("B"))() + station.mergePoly(lXPolys, lPolys("A"), lPolys("B"))()
                ,
                groundFaces = (pipe.new
                + upperPolys.A
                + upperPolys.B
                + lowerPolys.A
                + lowerPolys.B
                + ((info.A.lower.used and not info.A.lower.isBridge) and ext.polys.lower.A.polys or {})
                + ((info.B.lower.used and not info.B.lower.isBridge) and ext.polys.lower.B.polys or {})
                + ((info.A.upper.used and not info.A.upper.isBridge) and ext.polys.upper.A.polys or {})
                + ((info.B.upper.used and not info.B.upper.isBridge) and ext.polys.upper.B.polys or {})
                )
                * pipe.mapFlatten(function(p)
                    return {
                        {face = func.map(p, coor.vec2Tuple), modes = {{type = "FILL", key = "building_paving_fill"}}},
                        {face = func.map(p, coor.vec2Tuple), modes = {{type = "STROKE_OUTER", key = "building_paving"}}}
                    }
                end)
            }
            
            -- End of generation
            -- Slope, Height, Mirror treatment
            return pipe.new
                * result
                * station.setRotation(({0, 1, 0.5})[params.slopeLevel + 1] * rad)
                * station.setSlope((params.slopeSign == 0 and 1 or -1) * (slopeList[params.slope + 1]))
                * station.setRotation(({0, -1, -0.5})[params.slopeLevel + 1] * rad)
                * station.setHeight(extraZ)
                * station.setMirror(params.isMir == 1)
    end
end

return {
    updateFn = updateFn,
    params = params,
    rList = rList
}
