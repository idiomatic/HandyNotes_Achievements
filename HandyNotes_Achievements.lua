-- Copyright 2015, r. brian harrison.  all rights reserved.


-- XXX config panel
-- XXX configurable icon path, width, height, alpha
-- XXX refresh pins on config change
-- XXX minimap-zoom-sensitive consolidation distance
-- XXX event debouncing
-- XXX onclick improvements: pop up menu
-- XXX variant tooltip styling for completed/justmine
-- XXX tooltip modifier-key
-- XXX exclude achievements tracked by other modules
-- XXX unavailable progressions, e.g. "60 Exalted Reputations"
-- XXX TheArgentColiseum#543 does not get pins in the instance map
-- XXX seasonal icon


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
HNA.ICON_SCALE = 2
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


function HNA:RGBToColorCode(rgba)
    local a = rgba.a
    if a == nil then a = 1.0 end
    return string.format("|c%02x%02x%02x%02x", a * 255, rgba.r * 255, rgba.g * 255, rgba.b * 255)
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

            if row.faction then
                local name, _, standing = GetFactionInfoByID(row.faction)
                tooltip:AddSeparator(2, 0, 0, 0, 0)
                tooltip:SetFont(GameTooltipTextSmall)
                local genderSuffix = (UnitSex("player") == 3 and "_FEMALE") or ""
                local reputation = HNA:RGBToColorCode(FACTION_BAR_COLORS[standing]) .. _G["FACTION_STANDING_LABEL" .. standing .. genderSuffix] .. "|r"
                tooltip:AddLine(name, reputation)
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


function HNA:OnClick(button, down, mapFile, nearCoord)
    if not down then
        if not AchievementFrame then
            AchievementFrame_LoadUI()
        end

        local shown = {}

        for nodeIndex = 1, #activeNodes[mapFile], 2 do
            local nodes = activeNodes[mapFile]
            local coord, row = nodes[nodeIndex], nodes[nodeIndex + 1]
            if HNA:HandyNotesCoordsNear(coord, nearCoord) and HNA:Valid(row) then
                local achievementID = row[1]
                if not shown[achievementID] then
                    shown[achievementID] = true
                    print(GetAchievementLink(achievementID))
                end
                --ShowUIPanel(AchievementFrame)
                --AchievementFrame_SelectAchievement(achievementID)
            end
        end
    end
end


function HNA:OnInitialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end


local function notifyUpdate(frame, event)
    -- print(string.format("%s:%s()", ADDON_NAME, event))
    HNA:UpdateVisible()
    HNA:SendMessage("HandyNotes_NotifyUpdate", ADDON_NAME)
end
    

function HNA:PLAYER_ENTERING_WORLD(event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    -- XXX causes low end systems to sieze
    --self:RegisterEvent("ACHIEVEMENT_EARNED")
    --self:RegisterEvent("CRITERIA_COMPLETE")
    --self:RegisterEvent("CRITERIA_EARNED")
    --self:RegisterEvent("CRITERIA_UPDATE")
    --self:RegisterEvent("QUEST_COMPLETE")
    -- XXX event for "... has been added to your pet journal"

    -- XXX ...
    local options = {
        type = "group",
        name = "Achievements",
        args = {
            completed = {
                type = "toggle",
                name = "Show completed",
                desc = "Show icons for achievements you have completed.",
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

    local factionGroup = UnitFactionGroup("player")
    if row.side ~= nil and row.side ~= "both" and row.side ~= string.lower(factionGroup) then
        return false
    end
    
    if HandyNotes_Achievements_ShowCompleted then return true end

    local _, _, _, completed, _, _, _, _, _, _, _, _, earnedByMe, _ = GetAchievementInfo(achievementID)
    if completed and (earnedByMe or not HandyNotes_Achievements_ShowJustMine) then return false end

    if type(row.criterion) == "number" then
        local criteriaDescription, _, completed = GetAchievementCriteriaInfoByID(achievementID, row.criterion)
        if completed or not criteriaDescription then return false end
    elseif type(row.criterion) == "string" then
        local criteriaDescription, _, completed = HNA:GetAchievementCriteriaInfoByDescription(achievementID, row.criterion)
        if completed or not criteriaDescription then return false end
    end

    if row.quest then
        completed = IsQuestFlaggedCompleted(row.quest)
        if completed then return false end
    end

    if row.faction then
        local _, _, standing = GetFactionInfoByID(row.faction)
        completed = (standing == 8)
        if completed then return false end
    end

    return true
end


function HNA:GetNodes(mapFile, minimap, dungeonLevel)
    -- recursive function to generate valid achievements, sometimes projected into outer zones or consolidated pins
    local function validRows(mapFile, dungeonLevel, overrideMapFile, overrideCoord)
        local rows = AchievementLocations:Get(mapFile)
        for _, row in ipairs(rows or EMPTY) do
            if (dungeonLevel or row.floor) == (row.floor or dungeonLevel) then
                if self:Valid(row) then
                    local coord = row[2] and row[3] and row[2] * 1e8 + row[3] * 1e4
                    coroutine.yield(overrideMapFile or mapFile, overrideCoord or coord or self.DEFAULT_COORD, row)
                end
            end
        end

        local zones = HandyNotes:GetContinentZoneList(mapFile)
        for _, subMap in ipairs(zones or EMPTY) do
            local subMapFile = HandyNotes:GetMapIDtoMapFile(subMap)
            -- put this zone's achievements on the world map, all on one pin
            -- overrideMapFile and overrideCoord are likely nil
            validRows(subMapFile, nil, overrideMapFile, overrideCoord or (HandyNotes_Achievements_CleanContinents and self.ZONE_COORD))
        end

        local instances = InstanceLocations:GetBelow(mapFile)
        for _, instanceMapFile in ipairs(instances or EMPTY) do
            local overrideMapFile, instanceX, instanceY = unpack(InstanceLocations:GetLocation(instanceMapFile))
            local coord = instanceX and instanceY and instanceX * 1e8 + instanceY * 1e4
            validRows(instanceMapFile, nil, overrideMapFile, overrideCoord or coord)
        end
    end

    for _, nodes in pairs(activeNodes) do
        -- XXX skip minimap's
        wipe(nodes)
    end

    local rowsCo = coroutine.create(validRows)
    return function(state, value)
        local status, mF, coord, row = coroutine.resume(rowsCo, mapFile, dungeonLevel)
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
