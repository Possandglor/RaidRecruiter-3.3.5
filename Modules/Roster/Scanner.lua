local RR = RaidRecruiter

RR.Roster = RR.Roster or {}
RR.Roster.Scanner = {}

-- Проверяет, существует ли игрок в любой из списков ростера
local function FindPlayer(name)
    local lists = {
        "unassigned",
        "tanks",
        "healers",
        "dps",
    }

    for _, listId in ipairs(lists) do
        local list = RR.Data:GetPlayersInList(listId)

        for _, player in ipairs(list) do
            if player.name == name then
                return player, listId
            end
        end
    end

    return nil
end

function RR.Roster.Scanner:Scan()

    local changed = false

    -------------------------------------------------
    -- Кто сейчас состоит в группе/рейде
    -------------------------------------------------

    local currentPlayers = {}

    local function AddUnit(unit)

        if not UnitExists(unit) then
            return
        end

        local name = UnitName(unit)
        if not name then
            return
        end

        local _, class = UnitClass(unit)

        currentPlayers[name] = true

        local player = FindPlayer(name)

        if not player then

            RR.Data:AddPlayerToDB(
                "unassigned",
                name,
                class or "UNKNOWN",
                nil,
                "Добавлен автоматически"
            )

            RR.Utils:Log(name .. " автоматически добавлен в рейд.")

            changed = true
        end
    end

    -------------------------------------------------
    -- Сам игрок
    -------------------------------------------------

    AddUnit("player")

    -------------------------------------------------
    -- Рейд
    -------------------------------------------------

    if GetNumRaidMembers() > 0 then

        for i = 1, GetNumRaidMembers() do
            AddUnit("raid"..i)
        end

    else

        -------------------------------------------------
        -- Группа
        -------------------------------------------------

        for i = 1, GetNumPartyMembers() do
            AddUnit("party"..i)
        end

    end

    -------------------------------------------------
    -- Удаляем тех, кто вышел
    -------------------------------------------------

    local lists = {
        "unassigned",
        "tanks",
        "healers",
        "dps",
    }

    for _, listId in ipairs(lists) do

        local list = RR.Data:GetPlayersInList(listId)

        for i = #list, 1, -1 do

            local p = list[i]

            if not currentPlayers[p.name] then

                table.remove(list, i)

                RR.Utils:Log(p.name .. " покинул рейд.")

                changed = true

            end
        end
    end

    -------------------------------------------------

    if changed and RR.UI.MainWindow.frame and RR.UI.MainWindow.frame:IsShown() then
        RR.UI.MainWindow:Refresh()
    end

end