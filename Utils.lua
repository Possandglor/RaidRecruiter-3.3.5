local RR = RaidRecruiter
RR.Utils = {}

-- Красивый вывод в чат с префиксом аддона
function RR.Utils:Log(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffcc[RaidRecruiter]|r: " .. tostring(msg))
end

-- Таблица цветов классов для WoW 3.3.5
local CLASS_COLORS = {
    ["WARRIOR"]     = "C79C6E",
    ["PALADIN"]     = "F58CBA",
    ["HUNTER"]      = "ABD473",
    ["ROGUE"]       = "FFF569",
    ["PRIEST"]      = "FFFFFF",
    ["DEATHKNIGHT"] = "C41F3B",
    ["SHAMAN"]      = "0070DE",
    ["MAGE"]        = "69CCF0",
    ["WARLOCK"]     = "9482C9",
    ["DRUID"]       = "FF7D0A",
}

function RR.Utils:GetClassColor(classUpper)
    return CLASS_COLORS[classUpper] or "FFFFFF"
end