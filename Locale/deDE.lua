-- Copyright 2016, r. brian harrison.  all rights reserved.

local ADDON_NAME = ...
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
assert(AceLocale, string.format("%s requires %s", ADDON_NAME, "AceLocale-3.0"))

local L = AceLocale:NewLocale(ADDON_NAME, "deDE")
if not L then return end

-- import

L["%s requires %s"] = "%s erfordert %s"

-- config

L["Icon Scale"] = "Symbolgröße"
L["The size of the icons."] = "Die Größe der Symbole."
L["Icon Alpha"] = "Symboltransparenz"
L["The transparency of the icons."] = "Die Transparenz der Symbole."
L["Show Completed"] = "Abgeschlossene anzeigen"
-- L["Show map pins for achievements you have completed."] = "Abgeschlossene Errungenschaften anzeigen."
-- L["Consolidate Zone Pins"] = "Zonen Symbole zusammenlegen."
-- L["Show fewer map pins."] = "Weniger Kartensymbole anzeigen."
-- L["Just Mine"] = "Nur meine Errungenschaften"
-- L["Show more map pins by including achievements completed only by other characters."] = "Auch Kartemsymbole von anderen Charakteren abgeschlossene Errungenschaften anzeigen. "
-- L["Season Warning"] = "Sesonale Errungenschafts Erinnerung"
-- L["Days in advance to show pins for seasonal holiday achievements."] = "Wie viele Tage im Vorraus sollen mögliche Sesonale Errungenschaften angezeigt werden"