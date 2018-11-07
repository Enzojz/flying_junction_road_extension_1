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

local math = math
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local unpack = table.unpack

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

local function generateStructure(fitModel, fitModel2D)
    return function(lowerGroup, upperGroup, mDepth, models)
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
        
        local makeExtWall = junction.makeFn(models.mSidePillar, fitModel2D(0.5, 5), 0.5, mPlaceD)
        local makeExtWallFence = junction.makeFn(models.mRoofFenceS, fitModel2D(0.5, 5), 0.5, mPlaceD)
        local makeWall = junction.makeFn(models.mSidePillar, fitModel2D(0.5, 5), 0.5, mPlace)
        local makeRoof = junction.makeFn(models.mRoof, fitModel2D(5, 5), 5, mPlace)
        local makeSideFence = junction.makeFn(models.mRoofFenceS, fitModel2D(0.5, 5), 0.5, mPlace)
        local makeRoofFence = junction.makeFn(models.mRoofFenceS, fitModel2D(0.5, 5), 0.5, mPlaceR)
        
        local walls = lowerGroup.simpleWalls
        
        local upperFences = func.map(upperGroup.tracks, function(t)
            local inner = t + (-2.5)
            local outer = t + 2.5
            local diff = (t.inf > t.sup and 0.5 or -0.5) / t.r
            return {
                station.newModel(models.mSidePillar .. "_tl.mdl", coor.rotZ(pi * 0.5), mPlace(fitModel2D(5, 0.5)(false, true), inner, outer, t.inf, t.inf - diff)),
                station.newModel(models.mSidePillar .. "_br.mdl", coor.rotZ(pi * 0.5), mPlace(fitModel2D(5, 0.5)(true, false), inner, outer, t.inf, t.inf - diff)),
                station.newModel(models.mSidePillar .. "_tl.mdl", coor.rotZ(pi * 0.5), mPlace(fitModel2D(5, 0.5)(false, true), inner, outer, t.sup, t.sup + diff)),
                station.newModel(models.mSidePillar .. "_br.mdl", coor.rotZ(pi * 0.5), mPlace(fitModel2D(5, 0.5)(true, false), inner, outer, t.sup, t.sup + diff))
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
                name = sp .. _("Layout"),
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
                name = sp .. "\n" .. _("Structure Form"),
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
            
            
            local fitModel = junction.fitModel(params.isMir == 1)
            local fitModel2D = junction.fitModel2D(params.isMir == 1)
            
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
                lower = junction.buildCoors(info.A.lower.nbTracks, isLowerRoad and 1 or nbPerGroup, isLowerRoad and {trackWidth = streetWidth, wallWidth = 0.5} or nil),
                upper = junction.buildCoors(info.A.upper.nbTracks, info.A.upper.nbTracks, isUpperRoad and {trackWidth = streetWidth, wallWidth = 0.5} or nil)
            }
            
            local group = {
                A = jM.trackGroup(info.A, offsets),
                B = jM.trackGroup(info.B, offsets)
            }
            
            local structureOffsets = {
                lower = isLowerRoad
                and {
                    tracks = streetGroup.offset[params.isRoadSp + 1][params.streetType + 1],
                    walls = params.isRoadSp == 0 and {-0.25 - streetWidth * 0.5, 0.25 + streetWidth * 0.5} or {-0.25 - streetWidth * 0.5, 0, 0.25 + streetWidth * 0.5},
                    pavings = {-streetWidth * 0.5, streetWidth * 0.5}
                } or offsets.lower,
                upper = isUpperRoad
                and {
                    tracks = streetGroup.offset[1][params.streetType + 1],
                    walls = {-0.25 - streetWidth * 0.5, 0.25 + streetWidth * 0.5},
                    pavings = {-streetWidth * 0.5, streetWidth * 0.5}
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
                    walls = jM.retriveExt(extProtos("walls")),
                    pavings = jM.retriveExt(extProtos("pavings"))
                }
                
                return {
                    edges = jM.retriveX(jA.retriveTracks, preparedExt.tracks),
                    polys = jM.retriveX(jA.retrivePolys(false, isUpperRoad and streetWidth * 0.5 + 1 or false), preparedExt.tracks),
                    polysNarrow = jM.retriveX(jA.retrivePolys(false, isUpperRoad and streetWidth * 0.5 + 0.5 or false), preparedExt.tracks),
                    polysNarrow2 = jM.retriveX(jA.retrivePolys(false, isUpperRoad and streetWidth * 0.5 + 0.75 or false), preparedExt.tracks),
                    pavings = jM.retriveX(jA.retriveTrackPavings(fitModel, fitModel2D), preparedExt.pavings),
                    walls = jM.retriveX(jA.retriveWalls(fitModel, fitModel2D), preparedExt.walls)
                }, preparedExt
            end)()
            
            local trackEdges = {
                lower = jM.generateTrackGroups(group.A.lower.tracks, group.B.lower.tracks, {mpt = mDepth, mvec = coor.I()}),
                upper = jM.generateTrackGroups(group.A.upper.tracks, group.B.upper.tracks, {mpt = mTunnelZ * mDepth, mvec = coor.I()})
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
            
            local structureGen = params.bridgeForm == 0 and generateStructure(fitModel, fitModel2D) or jM.generateStructure(fitModel, fitModel2D)
            
            local structure = {
                A = structureGen(structureGroup.A.lower, structureGroup.A.upper, mTunnelZ * mDepth, models)[1],
                B = structureGen(structureGroup.B.lower, structureGroup.B.upper, mTunnelZ * mDepth, models)[2]
            }
            
            local innerWalls = params.bridgeForm == 0 and "simpleWalls" or "walls"
            
            
            local terrainIntersection = jM.findIntersection(
                info,
                tunnelHeight * heightFactor,
                preparedExt.walls.lower.A,
                isLowerRoad and {structureGroup.A.lower[innerWalls][1], structureGroup.A.lower[innerWalls][#structureGroup.A.lower[innerWalls]]} or group.A.lower[innerWalls],
                preparedExt.walls.lower.B,
                isLowerRoad and {structureGroup.B.lower[innerWalls][1], structureGroup.B.lower[innerWalls][#structureGroup.B.lower[innerWalls]]} or group.B.lower[innerWalls],
                preparedExt.walls.upper.A[1],
                preparedExt.walls.upper.B[#preparedExt.walls.upper.B]
            )
            local slopeWallModels = jM.slopeWalls(models, terrainIntersection, fitModel)
            
            local upperPolys = pipe.exec * function()
                local fz = function(_) return {y = heightFactor * tunnelHeight} end
                local tr = {
                    junction.trackLevel(fz, fz),
                    junction.trackLeft(fz),
                    junction.trackRight(fz)
                }
                local A = {junction.generatePolyArc(group.A.upper.tracks, "inf", "mid")(0, isUpperRoad and streetWidth * 0.5 or 2.75, tr)}
                local B = {junction.generatePolyArc(group.B.upper.tracks, "mid", "sup")(0, isUpperRoad and streetWidth * 0.5 or 2.75, tr)}
                return {
                    A = {
                        polys = A[1],
                        trackPolys = A[2],
                        leftPolys = A[3],
                        rightPolys = A[4]
                    },
                    B = {
                        polys = B[1],
                        trackPolys = B[2],
                        leftPolys = B[3],
                        rightPolys = B[4]
                    }
                }
            end
            
            local lowerLessPolys = jM.lowerTerrainPolys(terrainIntersection)
            local lowerSlotPolys = jM.lowerSlotPolys(terrainIntersection)
            
            local lowerPolys = pipe.exec * function()
                local fz = function(_) return {y = (heightFactor - 1) * tunnelHeight} end
                local tr = {junction.trackLevel(fz, fz)}
                local A = {junction.generatePolyArc(group.A.lower.tracks, "inf", "mid")(0, isLowerRoad and streetWidth * 0.5 or 2.75, tr)}
                local B = {junction.generatePolyArc(group.B.lower.tracks, "mid", "sup")(0, isLowerRoad and streetWidth * 0.5 or 2.75, tr)}
                return {
                    A = {
                        polys = A[1],
                        trackPolys = A[2]
                    },
                    B = {
                        polys = B[1],
                        trackPolys = B[2]
                    }
                }
            end
            
            local lowerTerrain = function(part) return {
                less = info[part].lower.isTerra and info[part].upper.isTerra and {
                    lowerLessPolys[part]
                } or {
                    lowerPolys[part].polys,
                    ext.polys.lower[part].polys,
                },
                greater = {
                    lowerPolys[part].trackPolys,
                    ext.polys.lower[part].trackPolys
                }
            }
            end
            
            local upperTerrain = function(part) return {
                less = (info[part].upper.isBridge or (not info[part].upper.isTerra and not info[part].lower.isTerra)) and {
                    upperPolys[part].polys,
                    ext.polys.upper[part].polys,
                } or {
                    upperPolys[part].trackPolys,
                    ext.polys.upper[part].trackPolys
                },
                greater = info[part].upper.isTerra and {
                    upperPolys[part].trackPolys,
                    ext.polys.upper[part].trackPolys,
                    upperPolys[part].leftPolys,
                    ext.polys.upper[part].leftPolys,
                    upperPolys[part].rightPolys,
                    ext.polys.upper[part].rightPolys
                } or {
                    upperPolys[part].polys,
                    ext.polys.upper[part].polys,
                }
            }
            end
            
            local lXPavings = (group.A.lower.pavings + group.B.lower.pavings)
                * pipe.map(
                    junction.makeFn("flying_junction/paving_base", fitModel(1, 5), 1,
                        function(fitModel, arcL, arcR, rad1, rad2)
                            local size = {
                                lt = arcL:pt(rad1):withZ((heightFactor - 1) * tunnelHeight),
                                lb = arcL:pt(rad2):withZ((heightFactor - 1) * tunnelHeight),
                                rt = arcR:pt(rad1):withZ((heightFactor - 1) * tunnelHeight),
                                rb = arcR:pt(rad2):withZ((heightFactor - 1) * tunnelHeight)
                            }
                            return fitModel(size)
                        end)
                )
                * pipe.flatten()
                * pipe.flatten()
            
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
                + withIfSolid("upper", "A")(ext.pavings.upper.A)
                + withIfSolid("upper", "B")(ext.pavings.upper.B)
                + (info.A.lower.used and ext.pavings.lower.A or {})
                + (info.B.lower.used and ext.pavings.lower.B or {})
                + lXPavings
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
                + (info.A.lower.used and slopeWallModels.A or {})
                + (info.B.lower.used and slopeWallModels.B or {})
                ,
                terrainAlignmentLists =
                station.mergePoly({less = station.projectPolys(coor.I())(
                    unpack(
                        pipe.new
                        + (info.A.lower.used and lowerTerrain("A").less or {})
                        + (info.B.lower.used and lowerTerrain("B").less or {})
                        + (info.A.upper.used and upperTerrain("A").less or {})
                        + (info.B.upper.used and upperTerrain("B").less or {})
                )
                )
                })()
                + station.mergePoly({greater = station.projectPolys(coor.I())(
                    unpack(
                        pipe.new
                        + (info.A.lower.used and lowerTerrain("A").greater or {})
                        + (info.B.lower.used and lowerTerrain("B").greater or {})
                        + (info.A.upper.used and upperTerrain("A").greater or {})
                        + (info.B.upper.used and upperTerrain("B").greater or {})
                )
                )
                })()
                ,
                groundFaces =
                (
                pipe.new
                + lowerPolys.A.polys + lowerPolys.B.polys
                + (info.A.lower.used and info.A.lower.isTerra and info.A.upper.isTerra and lowerSlotPolys.A or {})
                + (info.B.lower.used and info.B.lower.isTerra and info.B.upper.isTerra and lowerSlotPolys.B or {})
                + (not info.A.lower.used and {} or info.A.lower.isTerra and ext.polysNarrow.lower.A.polys or ext.polysNarrow2.lower.A.polys)
                + (not info.B.lower.used and {} or info.B.lower.isTerra and ext.polysNarrow.lower.B.polys or ext.polysNarrow2.lower.B.polys)
                )
                * pipe.map(function(p) return {face = (func.map(p, coor.vec2Tuple)), modes = {{type = "FILL", key = "hole"}}} end)
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
