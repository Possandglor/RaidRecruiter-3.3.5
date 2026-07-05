local RR = RaidRecruiter
RR.Chat = RR.Chat or {}
RR.Chat.Parser = {}

-- Словарь синонимов классов (с учетом опечаток и русского/английского)
local classKeywords = {
    ["warrior"] = "Воин", ["вар"] = "Воин", ["воин"] = "Воин", ["war"] = "Воин", ["протвар"] = "Воин",
    ["paladin"] = "Паладин", ["пал"] = "Паладин", ["паладин"] = "Паладин", ["pal"] = "Паладин", ["рпал"] = "Паладин", ["хпал"] = "Паладин", ["ппал"] = "Паладин",
    ["hunter"] = "Охотник", ["хант"] = "Охотник", ["охотник"] = "Охотник", ["hunt"] = "Охотник",
    ["rogue"] = "Разбойник", ["рог"] = "Разбойник", ["рога"] = "Разбойник",
    ["priest"] = "Жрец", ["прист"] = "Жрец", ["жрец"] = "Жрец", ["шп"] = "Жрец", ["дц"] = "Жрец", ["пріст"] = "Жрец", ["хприст"] = "Жрец",
    ["deathknight"] = "Рыцарь смерти", ["дк"] = "Рыцарь смерти", ["dk"] = "Рыцарь смерти", ["адк"] = "Рыцарь смерти", ["бдк"] = "Рыцарь смерти", ["фдк"] = "Рыцарь смерти",
    ["shaman"] = "Шаман", ["шам"] = "Шаман", ["шаман"] = "Шаман", ["элем"] = "Шаман", ["энх"] = "Шаман", ["ршам"] = "Шаман",
    ["mage"] = "Маг", ["маг"] = "Маг", ["mage"] = "Маг", ["фаер"] = "Маг", ["аркан"] = "Маг",
    ["warlock"] = "Чернокнижник", ["лок"] = "Чернокнижник", ["варлок"] = "Чернокнижник", ["демон"] = "Чернокнижник", ["афли"] = "Чернокнижник",
    ["druid"] = "Друид", ["дру"] = "Друид", ["друль"] = "Друид", ["друид"] = "Друид", ["сова"] = "Друид", ["кот"] = "Друид", ["мишка"] = "Друид", ["дерево"] = "Друид", ["рдру"] = "Друид"
}

-- Ключевые слова для инвайта
local inviteKeywords = {
    ["+"] = true, ["инв"] = true, ["inv"] = true, ["пати"] = true, ["группу"] = true, ["1"] = true
}

-- Ищем класс и гирскор
local function ParseMessage(text)
    -- В WoW символы могут быть в разных регистрах, приводим в нижний
    -- string.lower не работает с кириллицей корректно во всех локалях 3.3.5, 
    -- но для простых проверок базового русского клиентов сойдет:
    -- (Для надежности можно использовать utf8/словари)
    local lowerText = string.lower(text)
    
    local foundClass = "Не определено"
    -- Простая эвристика поиска
    for keyword, classicName in pairs(classKeywords) do
        -- Ищем подстроку
        if string.find(lowerText, keyword, 1, true) then
            foundClass = classicName
            break
        end
    end
    
    -- Пытаемся найти GS (например 5.5, 5900, 6k, 6.2k)
    local gs = text:match("%d+%.%d+") or text:match("%d%d%d%d") or text:match("%d+%.?%d*[kкKК]") or "-"
    
    -- Проверка на "инв"-слова, если класс не написали
    local wantsInvite = false
    if foundClass ~= "Не определено" or gs ~= "-" then
        wantsInvite = true
    end
    
    -- Ищем плюсики
    for kw in pairs(inviteKeywords) do
        if string.find(lowerText, kw, 1, true) then
            wantsInvite = true
            break
        end
    end
    
    return wantsInvite, foundClass, gs
end

function RR.Chat.Parser:OnWhisper(text, sender)
    -- Очищаем имя от названия сервера (для кросс-сервера, если он гипотетически есть)
    local shortName = sender:match("([^-]+)") or sender
    
    -- Не парсим свои же сообщения
    if shortName == UnitName("player") then return end
    
    local wantsInvite, parsedClass, parsedGS = ParseMessage(text)
    
    if wantsInvite then
        -- 1. Добавляем в 'Новые заявки'
        RR.Data:AddPlayerToDB("applicants", shortName, parsedClass, parsedGS, text)
        
        -- 2. Если включен автоинвайт, кидаем инвайт
        if RR.Data:GetConfigValue("autoInvite") then
            -- Функция 3.3.5
            InviteUnit(shortName)
            RR.Utils:Log("Отправлен авто-инвайт: " .. shortName)
        end
        
        -- 3. Обновляем UI (если он открыт)
        if RR.UI.MainWindow.frame and RR.UI.MainWindow.frame:IsShown() then
            RR.UI.MainWindow:Refresh()
        end
    end
end
