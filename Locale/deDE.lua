-- Copyright 2016, r. brian harrison.  all rights reserved.

local ADDON_NAME = ...
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
assert(AceLocale, string.format("%s requires %s", ADDON_NAME, "AceLocale-3.0"))

local L = AceLocale:NewLocale(ADDON_NAME, "deDE", true)
if not L then return end

-- import

L["%s requires %s"] = "%s erfordert %s"

-- config

L["Icon Scale"] = "Symbolgröße"
L["The size of the icons."] = "Die Größe der Symbole."
L["Icon Alpha"] = "Symboltransparenz"
L["The transparency of the icons."] = "Die Transparenz der Symbole."
L["Show Completed"] = "Abgeschlossene anzeigen"
