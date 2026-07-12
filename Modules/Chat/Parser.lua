local RR = RaidRecruiter
RR.Chat = RR.Chat or {}
RR.Chat.Parser = {}

-- =======================================================
-- СЛОВАРИ: спек -> {класс, роль}
-- Роли: "tanks", "healers", "dps", nil (не определено)
-- =======================================================

-- Спеки с явной ролью — приоритет над classKeywords
local specKeywords = {
    -- Танки
    ["протвар"]   = { class = "Воин",            role = "tanks" },
    ["протворіор"]= { class = "Воин",            role = "tanks" },
    ["фуривар"]   = { class = "Воин",            role = "dps"   },
    ["армс"]      = { class = "Воин",            role = "dps"   },
    ["фури"]      = { class = "Воин",            role = "dps"   },

    ["ппал"]      = { class = "Паладин",         role = "tanks" },
    ["протпал"]   = { class = "Паладин",         role = "tanks" },
    ["хпал"]      = { class = "Паладин",         role = "healers" },
    ["холипал"]   = { class = "Паладин",         role = "healers" },
    ["рпал"]      = { class = "Паладин",         role = "dps"   },

    ["бдк"]       = { class = "Рыцарь смерти",  role = "tanks" },
    ["блад"]      = { class = "Рыцарь смерти",  role = "tanks" },
    ["фдк"]       = { class = "Рыцарь смерти",  role = "dps"   },
    ["фрост дк"]  = { class = "Рыцарь смерти",  role = "dps"   },
    ["анхли дк"]  = { class = "Рыцарь смерти",  role = "dps"   },
    ["адк"]       = { class = "Рыцарь смерти",  role = "dps"   },

    ["медвдру"]   = { class = "Друид",           role = "tanks" },
    ["медведь"]   = { class = "Друид",           role = "tanks" },
    ["мишка"]     = { class = "Друид",           role = "tanks" },
    ["рдру"]      = { class = "Друид",           role = "healers" },
    ["ресто дру"] = { class = "Друид",           role = "healers" },
    ["рестодру"]  = { class = "Друид",           role = "healers" },
    ["дерево"]    = { class = "Друид",           role = "healers" },
    ["сова"]      = { class = "Друид",           role = "dps"   },
    ["баладру"]   = { class = "Друид",           role = "dps"   },
    ["кот"]       = { class = "Друид",           role = "dps"   },
    ["фераль"]    = { class = "Друид",           role = "dps"   },

    ["ршам"]      = { class = "Шаман",           role = "healers" },
    ["рестошам"]  = { class = "Шаман",           role = "healers" },
    ["хилшам"]    = { class = "Шаман",           role = "healers" },
    ["элем"]      = { class = "Шаман",           role = "dps"   },
    ["энх"]       = { class = "Шаман",           role = "dps"   },
    ["энхан"]     = { class = "Шаман",           role = "dps"   },

    ["дисц"]      = { class = "Жрец",            role = "healers" },
    ["дисцпр"]    = { class = "Жрец",            role = "healers" },
    ["хприст"]    = { class = "Жрец",            role = "healers" },
    ["хпріст"]    = { class = "Жрец",            role = "healers" },
    ["холі"]    = { class = "Жрец",            role = "healers" },
    ["холижрец"]  = { class = "Жрец",            role = "healers" },
    ["шп"]        = { class = "Жрец",            role = "dps"   },
    ["шадоу"]     = { class = "Жрец",            role = "dps"   },
    ["дц"]        = { class = "Жрец",            role = "healers"   },

    -- DPS-only классы / спеки
    ["хант"]      = { class = "Охотник",         role = "dps"   },
    ["охотник"]   = { class = "Охотник",         role = "dps"   },
    ["hunter"]    = { class = "Охотник",         role = "dps"   },
    ["рог"]       = { class = "Разбойник",       role = "dps"   },
    ["рога"]      = { class = "Разбойник",       role = "dps"   },
    ["rogue"]     = { class = "Разбойник",       role = "dps"   },
    ["маг"]       = { class = "Маг",             role = "dps"   },
    ["mage"]      = { class = "Маг",             role = "dps"   },
    ["фаер"]      = { class = "Маг",             role = "dps"   },
    ["фрост"]     = { class = "Маг",             role = "dps"   },
    ["аркан"]     = { class = "Маг",             role = "dps"   },
    ["лок"]       = { class = "Чернокнижник",   role = "dps"   },
    ["варлок"]    = { class = "Чернокнижник",   role = "dps"   },
    ["афли"]      = { class = "Чернокнижник",   role = "dps"   },
    ["демон"]     = { class = "Чернокнижник",   role = "dps"   },
    ["вар"]       = { class = "Воин",            role = "dps"   }, -- без префикса = фури
}

-- Запасной словарь для общих слов без спека (роль не определима)
local classOnly = {
    ["warrior"] = "Воин",    ["воин"] = "Воин",
    ["paladin"] = "Паладин", ["пал"] = "Паладин", ["паладин"] = "Паладин", ["pal"] = "Паладин",
    ["deathknight"] = "Рыцарь смерти", ["дк"] = "Рыцарь смерти", ["dk"] = "Рыцарь смерти",
    ["shaman"] = "Шаман",    ["шам"] = "Шаман",   ["шаман"] = "Шаман",
    ["priest"] = "Жрец",     ["прист"] = "Жрец",  ["жрец"] = "Жрец", ["пріст"] = "Жрец",
    ["druid"] = "Друид",     ["дру"] = "Друид",    ["друид"] = "Друид", ["друль"] = "Друид",
    ["warlock"] = "Чернокнижник",
}

-- Ключевые слова-триггеры на инвайт
local inviteKeywords = {
    ["+"] = true, ["инв"] = true, ["inv"] = true, ["пати"] = true, ["группу"] = true, ["1"] = true
}

-- =======================================================
-- Основная функция парсинга
-- =======================================================
local function ParseMessage(text)
    local lowerText = string.lower(text)

    local foundClass = "Не определено"
    local foundRole  = nil -- nil означает "не ясно, кидаем в заявки"

    -- Сначала ищем более специфичные спеки (длиннее = приоритетнее)
    -- Сортируем по убыванию длины ключа
    local sortedSpecs = {}
    for kw, data in pairs(specKeywords) do
        table.insert(sortedSpecs, { kw = kw, data = data })
    end
    table.sort(sortedSpecs, function(a, b) return #a.kw > #b.kw end)

    for _, entry in ipairs(sortedSpecs) do
        if string.find(lowerText, entry.kw, 1, true) then
            foundClass = entry.data.class
            foundRole  = entry.data.role
            break
        end
    end

    -- Если спек не нашли, смотрим в общем словаре (класс без роли)
    if foundRole == nil then
        for kw, cls in pairs(classOnly) do
            if string.find(lowerText, kw, 1, true) then
                foundClass = cls
                break
            end
        end
    end

    -- GS: 5.5 / 5900 / 6k / 6.2k
    local gs = text:match("%d+%.%d+") or text:match("%d%d%d%d") or text:match("%d+%.?%d*[kкKК]") or "-"

    -- Определяем, хочет ли человек инвайт
    local wantsInvite = (foundClass ~= "Не определено" or gs ~= "-")
    for kw in pairs(inviteKeywords) do
        if string.find(lowerText, kw, 1, true) then
            wantsInvite = true
            break
        end
    end

    return wantsInvite, foundClass, foundRole, gs
end

-- =======================================================
-- Обработчик входящего ЛС
-- =======================================================
function RR.Chat.Parser:OnWhisper(text, sender)
    local shortName = sender:match("([^-]+)") or sender

    -- Не парсим свои же сообщения
    if shortName == UnitName("player") then return end

    -- Если сбор не запущен — ничего не делаем
    if not RR.isRecruiting then return end

    local wantsInvite, parsedClass, parsedRole, parsedGS = ParseMessage(text)

    if wantsInvite then
        local targetList = parsedRole or "applicants"
        local player = RR.Data:UpsertPlayer(targetList, shortName, parsedClass, parsedGS, text)
        if player then
            player.autoAdded = nil
        end

        if parsedRole then
            local roleName = (parsedRole == "tanks" and "Танки") or
                             (parsedRole == "healers" and "Хилы") or "ДД"
            RR.Utils:Log(shortName .. " (" .. parsedClass .. ") → " .. roleName .. " | ГС: " .. parsedGS)
        else
            RR.Utils:Log(shortName .. " → Новые заявки (спек не определён) | ГС: " .. parsedGS)
        end

        -- Авто-инвайт (только если включён в настройках)
        if RR.Data:GetConfigValue("autoInvite") then
            InviteUnit(shortName)
        end

        -- Обновляем UI
        if RR.UI.MainWindow.frame and RR.UI.MainWindow.frame:IsShown() then
            RR.UI.MainWindow:Refresh()
        end
    end
end
