#!/usr/bin/env coffee
# dump https://docs.google.com/spreadsheets/d/1_s6zu-xXIqjUelmZO3ZdWB_C2fj-MFAxxMJkUbBwjxU/edit#gid=1492531208 into Lua

fs = require 'fs'
process = require 'process'
{ GoogleSpreadsheet } = require 'google-spreadsheet'

app = "AchievementLocations"
sheetID = '1_s6zu-xXIqjUelmZO3ZdWB_C2fj-MFAxxMJkUbBwjxU'
achievementWorksheetId = 1492531208
header = """-- this file is machine generated.  do not edit.

local AL = LibStub:GetLibrary("AchievementLocations-1.0")
local function A(row) AL:AddLocation(row) end

"""


dosify = (s) ->
    return s.replace(/\n/g, "\r\n")

createModule = (module) ->
    out = fs.createWriteStream("#{app}_#{module}.lua", mode:0o644)
    out.write dosify header
    return out

do ->
    doc = new GoogleSpreadsheet(sheetID)
    if process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL
        await doc.useServiceAccountAuth {
            client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL
            private_key: process.env.GOOGLE_PRIVATE_KEY
        }
    else
        await doc.useApiKey process.env.GOOGLE_API_KEY

    await doc.loadInfo()
    sheet = doc.sheetsById[achievementWorksheetId]
    rows = await sheet.getRows()

    outs = {}
    priorAchievementID = {}

    rows = rows.filter (row) -> row.mapfile
    rows.sort (a, b) ->
        ma = a.mapfile.toLowerCase()
        mb = b.mapfile.toLowerCase()
        return 0 if ma == mb
        return -1 if ma < mb
        return 1

    for {module, mapfile, achievement, criterion, x, y, floor, action, item, quest, faction, note, criteria, name, category, side, season} in rows
        module or= 'data'
        out = outs[module] or= createModule(module)

        if priorAchievementID[module] isnt achievement
            out.write dosify "\n-- #{category}: #{name}\n"
            priorAchievementID[module] = achievement
        out.write "A{#{JSON.stringify mapfile}"
        out.write ", #{achievement}"
        out.write ", #{x}, #{y}" if x or y
        
        if criterion
            criterion = JSON.stringify(criterion) unless /^\d+$/.test(criterion)
            out.write ", criterion=#{criterion}"

        out.write ", quest=#{quest}" if quest
        out.write ", faction=#{faction}" if faction
        out.write ", floor=#{floor}" if floor
        out.write ", action=#{JSON.stringify action}" if action
        out.write ", item=#{JSON.stringify item}" if item
        out.write ", note=#{JSON.stringify note}" if note
        out.write ", side=#{JSON.stringify side}" if side and side isnt 'both'
        out.write ", season=#{JSON.stringify season}" if season

        out.write "}"
        out.write " -- #{criteria}" if criteria
        out.write dosify "\n"

