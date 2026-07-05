local RR = RaidRecruiter
RR.UI.MainWindow = {}

function RR.UI.MainWindow:Create()
    if self.frame then return end

    local f = CreateFrame("Frame", "RaidRecruiterMainWindow", UIParent)
    self.frame = f
    
    -- Делаем окно выше под настройки (Ширина: 560, Высота: 610)
    f:SetSize(560, 610) 
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    
    f:SetBackdrop(RR.UI.BackdropTemplate)
    f:SetBackdropColor(0, 0, 0, 0.85) 
    
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -15)
    title:SetText("Raid Recruiter v0.2")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() self:Hide() end)

    -- ==============================================
    -- НАСТРОЙКИ СБОРА (Верхняя панель)
    -- ==============================================
    local raidNameInput = RR.UI:CreateEditBox(f, 80, 20, "Название рейда")
    raidNameInput:SetPoint("TOPLEFT", f, "TOPLEFT", 25, -50)
    raidNameInput:SetText(RR.Data:GetConfigValue("raidName") or "ЦЛК")
    raidNameInput:SetScript("OnTextChanged", function(self)
        RR.Data:SetConfigValue("raidName", self:GetText())
    end)

    local size10 = RR.UI:CreateRadioButton(f, "10")
    size10:SetPoint("LEFT", raidNameInput, "RIGHT", 15, 0)
    local size25 = RR.UI:CreateRadioButton(f, "25")
    size25:SetPoint("LEFT", size10, "RIGHT", 25, 0)
    
    local currentSize = RR.Data:GetConfigValue("raidSize")
    size10:SetChecked(currentSize == 10)
    size25:SetChecked(currentSize == 25)
    
    size10:SetScript("OnClick", function()
        size10:SetChecked(true)
        size25:SetChecked(false)
        RR.Data:SetConfigValue("raidSize", 10)
    end)
    size25:SetScript("OnClick", function()
        size25:SetChecked(true)
        size10:SetChecked(false)
        RR.Data:SetConfigValue("raidSize", 25)
    end)

    local commentInput = RR.UI:CreateEditBox(f, 160, 20, "Требования (GS, анролы)")
    commentInput:SetPoint("LEFT", size25, "RIGHT", 40, 0)
    commentInput:SetText(RR.Data:GetConfigValue("comment") or "")
    commentInput:SetScript("OnTextChanged", function(self)
        RR.Data:SetConfigValue("comment", self:GetText())
    end)

    local autoInviteCb = RR.UI:CreateCheckBox(f, "Авто-инвайт")
    autoInviteCb:SetPoint("LEFT", commentInput, "RIGHT", 20, 0)
    autoInviteCb:SetChecked(RR.Data:GetConfigValue("autoInvite"))
    autoInviteCb:SetScript("OnClick", function(self)
        RR.Data:SetConfigValue("autoInvite", self:GetChecked() == 1)
    end)

    local myRoleInput = RR.UI:CreateEditBox(f, 60, 20, "Я (т/х/дд/-)")
    myRoleInput:SetPoint("LEFT", autoInviteCb, "RIGHT", 75, 0)
    local curRole = RR.Data:GetConfigValue("myRole") or "none"
    if curRole == "tanks" then myRoleInput:SetText("т")
    elseif curRole == "healers" then myRoleInput:SetText("х")
    elseif curRole == "dps" then myRoleInput:SetText("дд")
    else myRoleInput:SetText("-") end
    
    myRoleInput:SetScript("OnTextChanged", function(self)
        local txt = string.lower(self:GetText() or "")
        if txt == "т" or txt == "t" or txt == "танк" then RR.Data:SetConfigValue("myRole", "tanks")
        elseif txt == "х" or txt == "h" or txt == "хил" then RR.Data:SetConfigValue("myRole", "healers")
        elseif txt == "д" or txt == "дд" or txt == "d" or txt == "dps" then RR.Data:SetConfigValue("myRole", "dps")
        else RR.Data:SetConfigValue("myRole", "none") end
    end)

    local templateInput = RR.UI:CreateEditBox(f, 370, 20, "Шаблон объявления")
    templateInput:SetPoint("TOPLEFT", raidNameInput, "BOTTOMLEFT", 0, -20)
    templateInput:SetText(RR.Data:GetConfigValue("announceTemplate") or "")
    templateInput:SetScript("OnTextChanged", function(self)
        RR.Data:SetConfigValue("announceTemplate", self:GetText())
    end)

    local channelsInput = RR.UI:CreateEditBox(f, 120, 20, "Каналы (через запятую)")
    channelsInput:SetPoint("LEFT", templateInput, "RIGHT", 20, 0)
    channelsInput:SetText(RR.Data:GetConfigValue("channels") or "")
    channelsInput:SetScript("OnTextChanged", function(self)
        RR.Data:SetConfigValue("channels", self:GetText())
    end)

    local helpBtn = CreateFrame("Button", nil, f)
    helpBtn:SetSize(20, 20)
    helpBtn:SetNormalFontObject("GameFontNormal")
    helpBtn:SetText("[?]")
    helpBtn:SetPoint("LEFT", channelsInput, "RIGHT", 5, 0)
    helpBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Доступные теги шаблонов", 1, 0.82, 0)
        GameTooltip:AddLine("Главный шаблон:", 1, 1, 1)
        GameTooltip:AddLine("%raid% - Название рейда\n%size% - Выбранный размер\n%comment% - Требования\n%current% - Набрано\n%max% - Максимум\n%need% - Требуемые роли", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Формат ролей (Т/Х/ДД):", 1, 1, 1)
        GameTooltip:AddLine("%d - Сколько добрать\n%c - Текущее количество\n%m - Максимум (цель)", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local intervalInput = RR.UI:CreateEditBox(f, 30, 20, "Сек")
    intervalInput:SetPoint("LEFT", helpBtn, "RIGHT", 15, 0)
    intervalInput:SetText(tostring(RR.Data:GetConfigValue("announceInterval") or 60))
    intervalInput:SetNumeric(true)
    intervalInput:SetScript("OnTextChanged", function(self)
        RR.Data:SetConfigValue("announceInterval", tonumber(self:GetText()) or 60)
    end)

    -- ==============================================
    -- ЧИСЛО РОЛЕЙ И ИХ ФОРМАТИРОВАНИЕ (Третья панель)
    -- ==============================================
    local cfg = RR.Data:GetConfig()

    local function CreateRoleSetting(parent, x, y, label, roleKey, defTarget)
        local countInput = RR.UI:CreateEditBox(parent, 25, 20, label)
        countInput:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        countInput:SetText(tostring(cfg.targets[roleKey] or defTarget))
        countInput:SetNumeric(true)
        countInput:SetScript("OnTextChanged", function(self)
            cfg.targets[roleKey] = tonumber(self:GetText()) or 0
        end)

        local formatInput = RR.UI:CreateEditBox(parent, 75, 20, "Формат")
        formatInput:SetPoint("LEFT", countInput, "RIGHT", 15, 0)
        formatInput:SetText(cfg.needFormat[roleKey] or ("%d " .. roleKey))
        formatInput:SetScript("OnTextChanged", function(self)
            cfg.needFormat[roleKey] = self:GetText()
        end)
        
        return formatInput
    end

    local tFmt = CreateRoleSetting(f, 25, -130, "Танки", "tanks", 2)
    local hFmt = CreateRoleSetting(f, 155, -130, "Хилы", "healers", 5)
    local dFmt = CreateRoleSetting(f, 285, -130, "ДД", "dps", 18)

    local sepInput = RR.UI:CreateEditBox(f, 40, 20, "Разделитель")
    sepInput:SetPoint("LEFT", dFmt, "RIGHT", 15, 0)
    sepInput:SetText(cfg.needFormat.separator or ", ")
    sepInput:SetScript("OnTextChanged", function(self)
        cfg.needFormat.separator = self:GetText()
    end)

    local fullInput = RR.UI:CreateEditBox(f, 65, 20, "Если Фул")
    fullInput:SetPoint("LEFT", sepInput, "RIGHT", 15, 0)
    fullInput:SetText(cfg.needFormat.fullText or "фул")
    fullInput:SetScript("OnTextChanged", function(self)
        cfg.needFormat.fullText = self:GetText()
    end)

    -- ==============================================
    -- КОМПОНОВКА СПИСКОВ (СЕТКА)
    -- ==============================================
    self.lists = {}
    
    -- 1. Новые заявки (Левая колонка, высокая)
    self.lists.applicants = RR.UI.PlayerList:Create(f, "applicants", "Новые заявки", 170, 390)
    self.lists.applicants:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -180)

    -- 2. Танки (Центральная колонка, верх)
    self.lists.tanks = RR.UI.PlayerList:Create(f, "tanks", "Танки", 170, 110)
    self.lists.tanks:SetPoint("TOPLEFT", self.lists.applicants, "TOPRIGHT", 10, 0)

    -- 3. Хилы (Центральная колонка, середина)
    self.lists.healers = RR.UI.PlayerList:Create(f, "healers", "Хилы", 170, 130)
    self.lists.healers:SetPoint("TOP", self.lists.tanks, "BOTTOM", 0, -10)

    -- 4. Отклоненные (Центральная колонка, низ)
    self.lists.rejected = RR.UI.PlayerList:Create(f, "rejected", "Отклоненные", 170, 130)
    self.lists.rejected:SetPoint("TOP", self.lists.healers, "BOTTOM", 0, -10)

    -- 5. ДД (Правая колонка, высокая, так как их всегда много)
    self.lists.dps = RR.UI.PlayerList:Create(f, "dps", "ДД", 170, 390)
    self.lists.dps:SetPoint("TOPLEFT", self.lists.tanks, "TOPRIGHT", 10, 0)

    -- ==============================================
    -- ДАННЫЕ БОЛЬШЕ НЕ СОЗДАЮТСЯ В UI (Только через RR.Data и Refresh)
    -- ==============================================

    local testBtn = RR.UI:CreateButton(f, "Только текст", 100, 24)
    testBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 10)
    testBtn:SetScript("OnClick", function()
        if RR.Chat and RR.Chat.Advertisement then
            RR.Chat.Advertisement:Send()
        else
            RR.Utils:Log("Ошибка: Модуль Advertisement не загружен.")
        end
    end)
    
    local startBtn = RR.UI:CreateButton(f, "НАЧАТЬ СПАМ", 150, 24)
    startBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    startBtn:SetScript("OnClick", function()
        if RR.Chat and RR.Chat.Advertisement then RR.Chat.Advertisement:StartBroadcast() end
    end)

    local stopBtn = RR.UI:CreateButton(f, "Остановить", 120, 24)
    stopBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 10)
    stopBtn:SetScript("OnClick", function()
        if RR.Chat and RR.Chat.Advertisement then RR.Chat.Advertisement:StopBroadcast() end
    end)

    f:Hide()
end

function RR.UI.MainWindow:Show()
    if not self.frame then self:Create() end
    self:Refresh()
    self.frame:Show()
end

function RR.UI.MainWindow:Hide()
    if self.frame then self.frame:Hide() end
end

function RR.UI.MainWindow:Toggle()
    if not self.frame or not self.frame:IsShown() then
        self:Show()
    else
        self:Hide()
    end
end

-- Основной метод обновления данных UI (Читает из Database и рисует в колонках)
function RR.UI.MainWindow:Refresh()
    if not self.frame then return end
    
    -- Проходим по всем созданным спискам
    for listId, listPanel in pairs(self.lists) do
        -- Очищаем визуальные элементы
        listPanel:Clear()
        
        -- Получаем актуальные данные из ростера
        local players = RR.Data:GetPlayersInList(listId)
        
        -- Перерисовываем
        for _, p in ipairs(players) do
            listPanel:AddPlayer(p.name, p.class, p.gs, p.whisper)
        end
    end
end