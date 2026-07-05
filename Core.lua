RaidRecruiter = RaidRecruiter or {}
local RR = RaidRecruiter

-- Создаем скрытый фрейм для прослушивания системных событий WoW
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "RaidRecruiter" then
        -- База данных загрузилась с жесткого диска
        RR.Data:Initialize()
        
    elseif event == "PLAYER_LOGIN" then
        -- Весь игровой мир готов, создаем UI элементы
        RR.UI.MainWindow:Create()
        RR.UI.MinimapButton:Create()
        
        RR.Utils:Log("Успешно загружен. Наберите /rr или нажмите кнопку у миникарты.")
    end
end)

-- Регистрация слэш-команд (/rr или /raidrecruiter)
SLASH_RAIDRECRUITER1 = "/rr"
SLASH_RAIDRECRUITER2 = "/raidrecruiter"

SlashCmdList["RAIDRECRUITER"] = function(msg)
    if RR.UI and RR.UI.MainWindow then
        RR.UI.MainWindow:Toggle()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000RaidRecruiter: Ошибка инициализации UI. Попробуйте /reload|r")
    end
end