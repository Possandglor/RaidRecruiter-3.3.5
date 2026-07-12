-- Инициализация глобального объекта аддона
RaidRecruiter = {}
local RR = RaidRecruiter

RR.Data = {}

-- Дефолтный конфиг (внутренняя структура)
local defaultDB = {
    config = {
        raidName = "ЦЛК",
        raidSize = 25,
        comment = "от 5.5 gs, анрол печень",
        announceInterval = 60,
        myRole = "dps", -- Может быть "tanks", "healers", "dps", "none"
        autoInvite = true,
        minimapPos = 45, -- Угол кнопки миникарты в градусах
        channels = "Поиск спутников",
        announceTemplate = "[%raid% - %size%] %comment%. Нужны: %need%. Спек и ГС в ПМ!",
        targets = {
            tanks = 2,
            healers = 5,
            dps = 18
        },
        needFormat = {
            tanks = "%d танк",
            healers = "%d хил",
            dps = "%d дд",
            separator = ", ",
            fullText = "рейд фул"
        }
    },
    applicants = {}, -- Новые заявки
    roster = {
        tanks = {},
        healers = {},
        dps = {},
    },
    rejected = {},
    history = {}
}

-- Инициализация базы данных (вызывается из Core.lua при PLAYER_LOGIN)
function RR.Data:Initialize()
    if not RaidRecruiterDB then
        RaidRecruiterDB = {}
    end
    
    -- Рекурсивно проверяем и заполняем дефолтные значения, если их нет
    local function mergeDefaults(src, dest)
        for k, v in pairs(src) do
            if type(v) == "table" then
                if type(dest[k]) ~= "table" then dest[k] = {} end
                mergeDefaults(v, dest[k])
            elseif dest[k] == nil then
                dest[k] = v
            end
        end
    end
    
    mergeDefaults(defaultDB, RaidRecruiterDB)
    self.db = RaidRecruiterDB
end

-- Геттеры и Сеттеры (Аналог Repository/Service слоя)
function RR.Data:GetConfig()
    return self.db.config
end

function RR.Data:GetConfigValue(key)
    return self.db.config[key]
end

function RR.Data:SetConfigValue(key, value)
    self.db.config[key] = value
end

function RR.Data:GetApplicants()
    return self.db.applicants
end

function RR.Data:GetListTable(listId)
    if listId == "applicants" then return self.db.applicants end
    if listId == "rejected" then return self.db.rejected end
    if self.db.roster[listId] then return self.db.roster[listId] end
    return nil
end

function RR.Data:GetPlayersInList(listId)
    return self:GetListTable(listId) or {}
end

function RR.Data:FindPlayerInList(listId, name)
    local tab = self:GetListTable(listId)
    if not tab then return nil end

    for i, p in ipairs(tab) do
        if p.name == name then
            return p, i
        end
    end

    return nil
end

function RR.Data:FindPlayer(name)
    local lists = {"applicants", "tanks", "healers", "dps", "rejected"}

    for _, listId in ipairs(lists) do
        local player = self:FindPlayerInList(listId, name)
        if player then
            return player, listId
        end
    end

    return nil
end

function RR.Data:BuildPlayerIndex()
    local index = {}
    local lists = {"applicants", "tanks", "healers", "dps", "rejected"}

    for _, listId in ipairs(lists) do
        local tab = self:GetListTable(listId)
        if tab then
            for i, p in ipairs(tab) do
                if p.name then
                    index[p.name] = {player = p, listId = listId, index = i}
                end
            end
        end
    end

    return index
end

function RR.Data:AddPlayerToDB(listId, name, class, gs, whisperText)
    local tab = self:GetListTable(listId)
    if tab then
        -- Проверяем, нет ли его уже
        for _, p in ipairs(tab) do
            if p.name == name then return end
        end
        table.insert(tab, {name = name, class = class, gs = gs, whisper = whisperText})
    end
end

function RR.Data:UpsertPlayer(listId, name, class, gs, whisperText)
    local targetTab = self:GetListTable(listId)
    if not targetTab then return nil end

    local player, currentList = self:FindPlayer(name)
    if player then
        player.class = class or player.class
        player.gs = gs or player.gs
        player.whisper = whisperText or player.whisper

        if currentList ~= listId then
            self:RemovePlayer(name, currentList)
            table.insert(targetTab, player)
        end

        return player
    end

    player = {name = name, class = class, gs = gs, whisper = whisperText}
    table.insert(targetTab, player)
    return player
end

function RR.Data:RemovePlayer(playerName, listId)
    local tab = self:GetListTable(listId)
    if not tab then return false end

    for i = #tab, 1, -1 do
        if tab[i].name == playerName then
            table.remove(tab, i)
            return true
        end
    end

    return false
end

function RR.Data:RemovePlayerEverywhere(playerName)
    local removed = false
    local lists = {"applicants", "tanks", "healers", "dps", "rejected"}

    for _, listId in ipairs(lists) do
        if self:RemovePlayer(playerName, listId) then
            removed = true
        end
    end

    return removed
end

function RR.Data:MovePlayer(playerName, fromList, toList)
    if fromList == toList then return end
    
    local sourceTab = self:GetListTable(fromList)
    local targetTab = self:GetListTable(toList)
    
    if sourceTab and targetTab then
        local playerObj = nil
        for i, p in ipairs(sourceTab) do
            if p.name == playerName then
                playerObj = table.remove(sourceTab, i)
                break
            end
        end
        
        if playerObj then
            table.insert(targetTab, playerObj)
        end
    end
end

-- Синхронизирует ростер с текущим составом группы/рейда.
-- Игроков из tanks/healers/dps, которых нет в группе, перемещает в rejected.
-- Возвращает количество перемещённых игроков.
function RR.Data:SyncWithGroupRoster()
    -- Строим словарь кто сейчас в группе/рейде (имя -> true)
    local inGroup = {}
    
    -- Добавляем самого игрока
    local myName = UnitName("player")
    if myName then inGroup[myName] = true end
    
    -- Проверяем рейд (до 40 слотов)
    local raidSize = GetNumRaidMembers()
    if raidSize > 0 then
        for i = 1, raidSize do
            local name = UnitName("raid" .. i)
            if name then inGroup[name] = true end
        end
    else
        -- Если не в рейде, проверяем обычную группу (до 4 участников)
        local partySize = GetNumPartyMembers()
        for i = 1, partySize do
            local name = UnitName("party" .. i)
            if name then inGroup[name] = true end
        end
    end
    
    local movedCount = 0
    local rosterLists = {"tanks", "healers", "dps"}
    
    for _, listId in ipairs(rosterLists) do
        local tab = self:GetListTable(listId)
        if tab then
            -- Идем с конца, чтобы безопасно удалять элементы
            for i = #tab, 1, -1 do
                local p = tab[i]
                if not inGroup[p.name] then
                    -- Игрока нет в группе — перемещаем в отклоненные
                    local playerObj = table.remove(tab, i)
                    playerObj.leftReason = "Покинул группу"
                    table.insert(self.db.rejected, playerObj)
                    movedCount = movedCount + 1
                    RR.Utils:Log(p.name .. " покинул группу — перемещён в Отклоненные.")
                end
            end
        end
    end
    
    return movedCount
end
