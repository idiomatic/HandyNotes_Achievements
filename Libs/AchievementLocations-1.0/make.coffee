#!/usr/bin/env coffee
# dump https://docs.google.com/spreadsheets/d/1_s6zu-xXIqjUelmZO3ZdWB_C2fj-MFAxxMJkUbBwjxU/edit#gid=1492531208 into Lua

fs = require 'fs'
GoogleSpreadsheet = require 'google-spreadsheet'

app = "AchievementLocations"
sheetID = '1_s6zu-xXIqjUelmZO3ZdWB_C2fj-MFAxxMJkUbBwjxU'
achievementWorksheet = 'ooom4sy'
header = """-- this file is machine generated.  do not edit.

local AL = LibStub:GetLibrary("AchievementLocations-1.0")
local function A(row) AL:AddLocation(row) end

"""


sheet = new GoogleSpreadsheet(sheetID)

createModule = (module) ->
    out = fs.createWriteStream("#{app}_#{module}.lua", mode:0o644)
    out.write header
    return out

sheet.getRows achievementWorksheet, {query: 'mapfile != ""', orderby: 'mapfile'}, (err, data) ->
    # XXX exit status?
    return console.error err if err

    outs = {}
    priorAchievementID = {}

    for {module, mapfile, achievementid, criterionid, criterion, x, y, floor, action, itemid, note, criteria, name, category} in data
        module or= 'data'
        out = outs[module] or= createModule(module)

        if priorAchievementID[module] isnt achievementid
            out.write "\n-- #{category}: #{name}\n"
            priorAchievementID[module] = achievementid
        out.write "A{#{JSON.stringify mapfile}"
        out.write ", #{achievementid}"
        if x or y
            out.write ", #{x}, #{y}"

        if criterion
            out.write ", criterion=#{JSON.stringify criterion}"
        else if criterionid
            out.write ", criterion=#{criterionid}"

        out.write ", floor=#{floor}" if floor
        out.write ", action=#{JSON.stringify action}" if action
        out.write ", item=#{JSON.stringify itemid}" if itemid
        out.write ", note=#{JSON.stringify note}" if note

        out.write "}"
        out.write " -- #{criteria}" if criteria
        out.write "\n"
