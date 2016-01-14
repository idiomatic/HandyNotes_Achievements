-- Copyright 2015, r. brian harrison.  all rights reserved.

local ADDON_NAME = ...
local HNA = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceTimer-3.0")
if not HNA then return end

local AchievementLocations = LibStub:GetLibrary("AchievementLocations-1.0")
assert(AchievementLocations, string.format("%s requires AchievementLocations-1.0", ADDON_NAME))

local InstanceLocations = LibStub:GetLibrary("InstanceLocations-1.0")
assert(InstanceLocations, string.format("%s requires InstanceLocations-1.0", ADDON_NAME))

local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes", true)
assert(HandyNotes, string.format("%s requires HandyNotes", ADDON_NAME))

local QTip = LibStub("LibQTip-1.0")
assert(QTip, string.format("%s requires LibQTip-1.0", ADDON_NAME))


HNA.ICON_PATH = "Interface/AchievementFrame/UI-Achievement-TinyShield"
HNA.ICON_SCALE = 5
HNA.ICON_ALPHA = 1.0
HNA.NEAR = 0.03
HNA.DEFAULT_COORD = 50005000
HNA.ZONE_COORD = 50005000

local EMPTY = {}
local visible = {}
local tooltip
local activeNodes = {}


function HNA:GetAchievementCriteriaInfoByDescription(achievementID, description)
    for i = 1, GetAchievementNumCriteria(achievementID) do
        local retval = {GetAchievementCriteriaInfo(achievementID, i)}
        if description == retval[1] then
            return unpack(retval, 1, 10)
        end
    end
end


function HNA:HandyNotesCoordsNear(c, coord)
    --return c == coord
    -- within 3% of the map
    local dx = (c - coord) / 1e8
    local dy = (c % 1e4 - coord % 1e4) / 1e4
    return dx * dx + dy * dy < self.NEAR * self.NEAR
end


function HNA:OnEnter(mapFile, nearCoord)
    tooltip = QTip:Acquire(ADDON_NAME, 2, "LEFT", "RIGHT")
    local firstRow = true
    local previousAchievementID

    for nodeIndex = 1, #activeNodes[mapFile], 2 do
        local nodes = activeNodes[mapFile]
        local coord, row = nodes[nodeIndex], nodes[nodeIndex + 1]
        if HNA:HandyNotesCoordsNear(coord, nearCoord) and HNA:Valid(row) then
            local achievementID = row[1]
            local criterion = row.criterion

            local _, name, points, completed, _, _, _, description, _, _, _, _, _, _ = GetAchievementInfo(achievementID)
            
            if achievementID ~= previousAchievementID then
                if not firstRow then
                    tooltip:AddSeparator(2, 0, 0, 0, 0)
                    tooltip:AddSeparator(1, 1, 1, 1, 0.5)
                    tooltip:AddSeparator(2, 0, 0, 0, 0)
                end
                firstRow = false

                tooltip:SetHeaderFont(GameFontGreenLarge)
                tooltip:AddHeader(name)

                tooltip:SetFont(GameTooltipTextSmall)
                tooltip:AddLine(description)
                previousAchievementID = achievementID
            end

            if criterion then
                local criterionDescription, quantityString
                if type(criterion) == "number" then
                    criterionDescription, _, _, _, _, _, _, _, quantityString, _ = GetAchievementCriteriaInfoByID(achievementID, criterion)
                else
                    criterionDescription, _, _, _, _, _, _, _, quantityString, _ = HNA:GetAchievementCriteriaInfoByDescription(achievementID, criterion)
                end
                
                if quantityString == "0" then
                    quantityString = ""
                end

                if criterionDescription then
                    tooltip:AddSeparator(2, 0, 0, 0, 0)
                    tooltip:SetFont(GameTooltipTextSmall)
                    tooltip:AddLine(criterionDescription, quantityString)
                end
            end
        end
    end

    tooltip:SmartAnchorTo(self)
    tooltip:Show()
end


function HNA:OnLeave(mapFile, coord)
    QTip:Release(tooltip)
end


function HNA:OnClick(button, down, mapFile, coord)
    if not AchievementFrame then
        AchievementFrame_LoadUI()
    end
    -- XXX ...
    if achievementID then
        ShowUIPanel(AchievementFrame)
        AchievementFrame_SelectAchievement(achievementID)
    end
end


function HNA:OnInitialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end


local function notifyUpdate(frame, event)
    HNA:UpdateVisible()
    HNA:SendMessage("HandyNotes_NotifyUpdate", ADDON_NAME)
end
    

function HNA:PLAYER_ENTERING_WORLD(event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ACHIEVEMENT_EARNED")
    self:RegisterEvent("CRITERIA_COMPLETE")
    self:RegisterEvent("CRITERIA_EARNED")
    self:RegisterEvent("CRITERIA_UPDATE")
    self:RegisterEvent("QUEST_COMPLETE")
    -- XXX ...
    local options = {
        name = "Achievements",
        args = {
            completed = {
                name = "Show completed",
                desc = "Show icons for achievements you have completed.",
                tpye = "toggle",
                width = "full",
                arg = "completed",
                order = 1,
            },
            icon_scale = {
                type = "range",
                name = "Icon Scale",
                desc = "The size of the icons.",
                min = 0.3, max = 5, step = 0.1,
                arg = "icon_scale",
                order = 3,
            },
            icon_alpha = {
                type = "range",
                name = "Icon Alpha",
                desc = "The transparency of the icons.",
                min = 0, max = 1, step = 0.01,
                arg = "icon_alpha",
                order = 4,
            },
        },
    }
    -- XXX
    options = {}
    HandyNotes:RegisterPluginDB(ADDON_NAME, self, options)
    notifyUpdate(nil, event)
end


HNA.ACHIEVEMENT_EARNED = notifyUpdate
HNA.CRITERIA_COMPLETE  = notifyUpdate
HNA.CRITERIA_EARNED    = notifyUpdate
HNA.CRITERIA_UPDATE    = notifyUpdate
HNA.QUEST_COMPLETE     = notifyUpdate


function HNA:UpdateVisible()
    for _, categoryID in ipairs(GetCategoryList()) do
        for i = 1, GetCategoryNumAchievements(categoryID) do
            local achievementID = GetAchievementInfo(categoryID, i)
            if achievementID then
                visible[achievementID] = true
            end
        end
    end
end


function HNA:Valid(row)
    local achievementID = row[1]
    if not visible[achievementID] then return false end
    if HandyNotes_Achievements_ShowCompleted then return true end

    local _, _, _, completed, _, _, _, _, _, _, _, _, earnedByMe, _ = GetAchievementInfo(achievementID)
    -- XXX justmine
    if completed then return false end

    if type(row.criterion) == "number" then
        _, _, completed = GetAchievementCriteriaInfoByID(achievementID, row.criterion)
    elseif type(row.criterion) == "string" then
        _, _, completed = HNA:GetAchievementCriteriaInfoByDescription(achievementID, row.criterion)
    end
    if completed then return false end

    if row.quest then
        return not IsQuestFlaggedCompleted(row.quest)
    end

    return true
end


function HNA:GetNodes(mapFile, minimap, dungeonLevel)
    -- recursive function to generate valid achievements, sometimes projected into outer zones or consolidated pins
    local function validRows(mapFile, overrideMapFile, overrideCoord)
        local rows = AchievementLocations:Get(mapFile)
        for _, row in ipairs(rows or EMPTY) do
            if self:Valid(row) then
                local coord = row[2] and row[3] and row[2] * 1e8 + row[3] * 1e4
                coroutine.yield(overrideMapFile or mapFile, overrideCoord or coord or self.DEFAULT_COORD, row)
            end
        end

        local zones = HandyNotes:GetContinentZoneList(mapFile)
        for _, subMap in ipairs(zones or EMPTY) do
            local subMapFile = HandyNotes:GetMapIDtoMapFile(subMap)
            -- put this zone's achievements on the world map, all on one pin
            -- overrideMapFile and overrideCoord are likely nil
            validRows(subMapFile, overrideMapFile, overrideCoord or (HandyNotes_Achievements_CleanContinents and self.ZONE_COORD))
        end

        local instances = InstanceLocations:GetBelow(mapFile)
        for _, instanceMapFile in ipairs(instances or EMPTY) do
            local overrideMapFile, instanceX, instanceY = unpack(InstanceLocations:GetLocation(instanceMapFile))
            local coord = instanceX and instanceY and instanceX * 1e8 + instanceY * 1e4
            validRows(instanceMapFile, overrideMapFile, overrideCoord or coord)
        end
    end

    for _, nodes in pairs(activeNodes) do
        wipe(nodes)
    end

    local rowsCo = coroutine.create(validRows)
    return function(state, value)
        local status, mF, coord, row = coroutine.resume(rowsCo, mapFile)
        if not status then
            print(string.format("|cffff0000%s Error:|r %s", ADDON_NAME, tostring(mF)))
            return nil
        end
        if not row then
            return nil
        end
        if not activeNodes[mF] then
            activeNodes[mF] = {}
        end
        table.insert(activeNodes[mF], coord)
        table.insert(activeNodes[mF], row)
        -- HandyNotes does iterators wrong: the first value should be a iterator variable (cursor), eliminating the need for a "value" closure or coroutine
        -- added row for OnEnter
        return coord, mF, self.ICON_PATH, self.ICON_SCALE, self.ICON_ALPHA, nil, row
    end, nil
end
