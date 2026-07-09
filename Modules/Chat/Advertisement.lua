local RR = RaidRecruiter
RR.Chat = RR.Chat or {}
RR.Chat.Advertisement = {}

-- Построение строки объявления на основе шаблона и текущего ростера
function RR.Chat.Advertisement:Build()
    local config = RR.Data:GetConfig()
    local template = config.announceTemplate or ""
    
    local text = template
    text = text:gsub("%%raid%%", function() return config.raidName or "" end)
    text = text:gsub("%%size%%", function() return tostring(config.raidSize) or "" end)
    text = text:gsub("%%comment%%", function() return config.comment or "" end)
    
    -- Считаем количество занятых мест по ролям + добавляем самого игрока
    local tanksCt = #RR.Data:GetPlayersInList("tanks")
    local healsCt = #RR.Data:GetPlayersInList("healers")
    local dpsCt   = #RR.Data:GetPlayersInList("dps")
    
    local myRole = config.myRole or "none"
    if myRole == "tanks" then tanksCt = tanksCt + 1
    elseif myRole == "healers" then healsCt = healsCt + 1
    elseif myRole == "dps" then dpsCt = dpsCt + 1 end
    
    local current = tanksCt + healsCt + dpsCt
    text = text:gsub("%%current%%", function() return tostring(current) end)
    text = text:gsub("%%max%%", function() return tostring(config.raidSize) end)
    
    -- Высчитываем кого не хватает
    local needsConfig = config.targets or {tanks=2, healers=5, dps=18}
    local formats = config.needFormat or {
        tanks = "%d танк", healers = "%d хил", dps = "%d дд",
        separator = ", ", fullText = "рейд фул"
    }
    
    local needStrs = {}
    if tanksCt < needsConfig.tanks then 
        local dif = needsConfig.tanks - tanksCt
        local f = formats.tanks:gsub("%%d", function() return tostring(dif) end)
        f = f:gsub("%%c", function() return tostring(tanksCt) end)
        f = f:gsub("%%m", function() return tostring(needsConfig.tanks) end)
        table.insert(needStrs, f) 
    end
    
    if healsCt < needsConfig.healers then 
        local dif = needsConfig.healers - healsCt
        local f = formats.healers:gsub("%%d", function() return tostring(dif) end)
        f = f:gsub("%%c", function() return tostring(healsCt) end)
        f = f:gsub("%%m", function() return tostring(needsConfig.healers) end)
        table.insert(needStrs, f) 
    end
    
    if dpsCt < needsConfig.dps then 
        local dif = needsConfig.dps - dpsCt
        local f = formats.dps:gsub("%%d", function() return tostring(dif) end)
        f = f:gsub("%%c", function() return tostring(dpsCt) end)
        f = f:gsub("%%m", function() return tostring(needsConfig.dps) end)
        table.insert(needStrs, f) 
    end
    
    local needText = formats.fullText
    if #needStrs > 0 then
        needText = table.concat(needStrs, formats.separator)
    end
    
    text = text:gsub("%%need%%", function() return needText end)
    
    return text
end

-- Отправка сообщений в настроенные каналы
function RR.Chat.Advertisement:Send()
    local msg = self:Build()
    
    local channelsStr = RR.Data:GetConfigValue("channels") or ""
    if channelsStr == "" then
        RR.Utils:Log("Локально (каналы не указаны): " .. msg)
        return
    end

    -- Разбиваем строку каналов (через запятую) и шлём сообщения
    for rawChan in string.gmatch(channelsStr, "[^,]+") do
        local chan = rawChan:match("^%s*(.-)%s*$") -- Убираем пробелы
        if chan and chan ~= "" then
            local upper = string.upper(chan)
            
            if upper == "GUILD" or upper == "ГИЛЬДИЯ" or chan == "/g" then
                SendChatMessage(msg, "GUILD")
            elseif upper == "RAID" or upper == "РЕЙД" or chan == "/raid" then
                SendChatMessage(msg, "RAID")
            elseif upper == "PARTY" or upper == "ГРУППА" or upper == "ПАТИ" or chan == "/p" then
                SendChatMessage(msg, "PARTY")
            elseif upper == "SAY" or upper == "СКАЗАТЬ" or chan == "/s" then
                SendChatMessage(msg, "SAY")
            elseif upper == "YELL" or upper == "КРИК" or chan == "/y" then
                SendChatMessage(msg, "YELL")
            else
                -- Если это номер канала или название публичного канала (Поиск спутников)
                local chanId = tonumber(chan) or chan
                local id, name = GetChannelName(chanId)
                if id and id > 0 then
                    SendChatMessage(msg, "CHANNEL", nil, id)
                else
                    RR.Utils:Log("Ошибка: Канал '" .. chan .. "' не найден или вы в нем не состоите.")
                end
            end
        end
    end
end

-- Управление автоматической рассылкой
function RR.Chat.Advertisement:StartBroadcast()
    if self.isBroadcasting then return end
    self.isBroadcasting = true
    RR.isRecruiting = true  -- Глобальный флаг: сбор активен
    self.timeSinceLast = 0
    
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    self.frame:SetScript("OnUpdate", function(f, elapsed)
        if not self.isBroadcasting then return end
        self.timeSinceLast = self.timeSinceLast + elapsed
        local interval = tonumber(RR.Data:GetConfigValue("announceInterval")) or 60
        if self.timeSinceLast >= interval then
            self.timeSinceLast = 0
            self:Send()
        end
    end)
    
    local interval = tonumber(RR.Data:GetConfigValue("announceInterval")) or 60
    RR.Utils:Log("Сбор запущен. Объявления каждые " .. interval .. " сек. Авто-инвайт по ЛС активен.")
    self:Send() -- Отправляем первый раз сразу
end

function RR.Chat.Advertisement:StopBroadcast()
    if not self.isBroadcasting then return end
    self.isBroadcasting = false
    RR.isRecruiting = false  -- Глобальный флаг: сбор остановлен
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    RR.Utils:Log("Сбор остановлен. Авто-инвайт по ЛС отключён.")
end
