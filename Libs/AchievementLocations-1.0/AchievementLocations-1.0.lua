-- Copyright (c) 2015, r. brian harrison.  All rights reserved.

local LIB_NAME = "AchievementLocations-1.0"
assert(LibStub, string.format("%s requires LibStub", LIB_NAME))

local AchievementLocations = LibStub:NewLibrary(LIB_NAME, 1)
if not AchievementLocations then return end


local EMPTY = {}


AchievementLocations.byMap = AchievementLocations.byMap or {}


function AchievementLocations:AddLocation(mapFile, achievementID, criterion, x, y, options)
    local row
    if type(mapFile) == "table" then
        row = mapFile
        mapFile = table.remove(row, 1)
    else
        row = {achievementID, criterion, x, y}
        row.note = options.note
        row.action = options.action
    end

    local map = self.byMap[mapFile]
    if not map then
        map = {}
        self.byMap[mapFile] = map
    end
    table.insert(map, row)
end


function AchievementLocations:Get(mapFile)
    return self.byMap[mapFile]
end
