RaidRecruiter = RaidRecruiter or {}
local RR = RaidRecruiter
RR.UI = RR.UI or {}
RR.UI.MinimapButton = RR.UI.MinimapButton or {}

function RR.UI.MinimapButton:Create()
    -- Проверяем, не создана ли уже кнопка
    if self.frame then return end

    local btn = CreateFrame("Button", "RaidRecruiterMinimapButton", Minimap)
    self.frame = btn
    
    btn:SetSize(31, 31)
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    btn:SetToplevel(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Иконка (взяли стандартную иконку сбора рейдов/глаза LFG для наглядности)
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodyGetsIn")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    
    -- Ободок кнопки миникарты
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)

    -- Обновление позиции кнопки на окружности миникарты
    function self:UpdatePosition()
        local angle = RR.Data:GetConfigValue("minimapPos") or 45
        -- Формула круга для миникарты WoW
        local x = math.cos(math.rad(angle)) * 80
        local y = math.sin(math.rad(angle)) * 80
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    -- Скрипты перетаскивания (Drag & Drop кнопки вокруг миникарты)
    btn:SetScript("OnDragStart", function(frame)
        frame:LockHighlight()
        frame:SetScript("OnUpdate", function(f)
            local xpos, ypos = GetCursorPosition()
            local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
            local scale = Minimap:GetEffectiveScale()
            
            local x = (xmin + 70) - (xpos / scale)
            local y = (ypos / scale) - (ymin + 70)
            
            local angle = math.deg(math.atan2(y, x))
            RR.Data:SetConfigValue("minimapPos", angle)
            self:UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(frame)
        frame:SetScript("OnUpdate", nil)
        frame:UnlockHighlight()
    end)

    -- Клик по кнопке открывает/закрывает главное окно
    btn:SetScript("OnClick", function(frame, button)
        if button == "LeftButton" then
            RR.UI.MainWindow:Toggle()
        end
    end)

    -- Тултип при наведении
    btn:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
        GameTooltip:SetText("RaidRecruiter", 1, 1, 1)
        GameTooltip:AddLine("ЛКМ: Открыть/Закрыть окно управления рейдом", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Перетаскивание: Переместить кнопку", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self:UpdatePosition()
end