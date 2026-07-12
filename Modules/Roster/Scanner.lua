local RR = RaidRecruiter

RR.Roster = RR.Roster or {}
RR.Roster.Scanner = {}

local function ShortName(name)
    return name and (name:match("([^-]+)") or name) or nil
end

local function RemoveMissingGroupPlayers(currentPlayers, silent)
    local changed = false
    local lists = {"applicants", "tanks", "healers", "dps"}

    for _, listId in ipairs(lists) do

        local list = RR.Data:GetPlayersInList(listId)

        for i = #list, 1, -1 do

            local p = list[i]

            if p.inGroup and not currentPlayers[p.name] then

                table.remove(list, i)

                if not silent then
                    RR.Utils:Log(p.name .. " покинул рейд.")
                end

                changed = true

            end
        end
    end

    return changed
end

function RR.Roster.Scanner:Scan(silent)

    local changed = false
    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    local currentPlayers = {}

    if raidCount == 0 and partyCount == 0 then
        local myName = ShortName(UnitName("player"))
        if myName then
            currentPlayers[myName] = true
        end

        changed = RemoveMissingGroupPlayers(currentPlayers, silent)
        if changed and RR.UI.MainWindow.frame and RR.UI.MainWindow.frame:IsShown() then
            RR.UI.MainWindow:Refresh()
        end
        return
    end

    local playerIndex = RR.Data:BuildPlayerIndex()

    -------------------------------------------------
    -- Кто сейчас состоит в группе/рейде
    -------------------------------------------------

    local function AddUnit(unit)

        if not UnitExists(unit) then
            return
        end

        if UnitIsUnit and UnitIsUnit(unit, "player") then
            return
        end

        local name = ShortName(UnitName(unit))
        if not name then
            return
        end

        local _, class = UnitClass(unit)

        currentPlayers[name] = true

        local entry = playerIndex[name]
        local player = entry and entry.player
        local listId = entry and entry.listId

        if not player then

            player = RR.Data:UpsertPlayer(
                "applicants",
                name,
                class or "UNKNOWN",
                nil,
                "Уже в группе/рейде"
            )

            if player then
                player.inGroup = true
                player.autoAdded = true
                playerIndex[name] = {player = player, listId = "applicants"}
            end

            if not silent then
                RR.Utils:Log(name .. " найден в группе и добавлен в заявки.")
            end

            changed = true

        elseif listId == "rejected" then

            player = RR.Data:UpsertPlayer("applicants", name, class or player.class or "UNKNOWN", player.gs, "Уже в группе/рейде")

            if player then
                player.inGroup = true
                player.autoAdded = true
                playerIndex[name] = {player = player, listId = "applicants"}
            end

            if not silent then
                RR.Utils:Log(name .. " снова найден в группе и возвращён в заявки.")
            end
            changed = true

        else

            player.inGroup = true
            if (not player.class or player.class == "UNKNOWN" or player.class == "Не определено") and class then
                player.class = class
            end

        end
    end

    -------------------------------------------------
    -- Сам игрок
    -------------------------------------------------

    local myName = ShortName(UnitName("player"))
    if myName then
        currentPlayers[myName] = true
    end

    -------------------------------------------------
    -- Рейд
    -------------------------------------------------

    if raidCount > 0 then

        for i = 1, raidCount do
            AddUnit("raid"..i)
        end

    else

        -------------------------------------------------
        -- Группа
        -------------------------------------------------

        for i = 1, partyCount do
            AddUnit("party"..i)
        end

    end

    -------------------------------------------------
    -- Удаляем тех, кто вышел
    -------------------------------------------------

    if RemoveMissingGroupPlayers(currentPlayers, silent) then
        changed = true
    end

    -------------------------------------------------

    if changed and RR.UI.MainWindow.frame and RR.UI.MainWindow.frame:IsShown() then
        RR.UI.MainWindow:Refresh()
    end

end
