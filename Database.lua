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