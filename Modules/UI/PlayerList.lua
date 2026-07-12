local RR = RaidRecruiter
RR.UI.PlayerList = {}

-- Метод создания панели-списка (колонки)
function RR.UI.PlayerList:Create(parent, listId, titleText, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame.listId = listId
    frame:SetSize(width, height)
    
    -- Фон списка (полупрозрачный черный с серой рамкой)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Заголовок колонки
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText(titleText)
    frame.title = title
    frame.titleText = titleText
    
    -- Невидимый контейнер для хранения самих кнопок игроков (с отступом от шапки)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -25)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    frame.content = content
    
    frame.items = {}

    function frame:SetTitleText(text)
        self.title:SetText(text or self.titleText)
    end

    -- Очистка списка
    function frame:Clear()
        for _, item in ipairs(self.items) do
            item:Hide()
            item:SetParent(nil)
        end
        self.items = {}
    end

    -- Внутренний метод колонки: добавляет плашку игрока
    function frame:AddPlayer(name, class, gs, whisperText)
        local btn = CreateFrame("Button", nil, self.content)
        btn:SetSize(width - 10, 20) 
        btn:SetMovable(true) -- Разрешаем перемещение
        
        -- Позиционирование: если первый, крепим к верху, иначе — под предыдущим
        if #self.items == 0 then
            btn:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", self.items[#self.items], "BOTTOMLEFT", 0, -2)
        end
        
        -- Имя в цвет класса
        local colorCode = RR.Utils:GetClassColor(string.upper(class or ""))
        local nameStr = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameStr:SetPoint("LEFT", btn, "LEFT", 5, 0)
        nameStr:SetText(("|cff%s%s|r"):format(colorCode, name))
        
        -- GS справа (если передан)
        if gs then
            local gsStr = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            gsStr:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            gsStr:SetText(gs)
        end
        
        -- Тултип (всплывающая подсказка) с оригинальным сообщением
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(name, 1, 1, 1)
            if whisperText then
                GameTooltip:AddLine("ЛС: " .. whisperText, 0.8, 0.8, 0.8, true)
            end
            GameTooltip:AddLine("ПКМ: удалить", 1, 0.25, 0.25)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        btn:RegisterForClicks("RightButtonUp")
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                GameTooltip:Hide()
                if RR.Data:RemovePlayer(name, frame.listId) then
                    RR.Utils:Log(name .. " удалён из списка.")
                    RR.UI.MainWindow:Refresh()
                end
            end
        end)
        
        -- Подсветка строки при наведении мышки
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(btn)

        -- ==========================================
        -- DRAG & DROP LOGIC
        -- ==========================================
        btn:RegisterForDrag("LeftButton")
        
        btn:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self:SetFrameStrata("TOOLTIP") -- чтобы быть поверх всех списков
        end)
        
        btn:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self:SetFrameStrata("HIGH") -- возвращаем обратно
            
            -- Проверяем, над какой колонкой отпустили мышку
            local targetListId = nil
            if RR.UI.MainWindow.lists then
                for id, listFrame in pairs(RR.UI.MainWindow.lists) do
                    if MouseIsOver(listFrame) then
                        targetListId = id
                        break
                    end
                end
            end
            
            -- Если перетащили в другую колонку — двигаем данные
            if targetListId and targetListId ~= frame.listId then
                RR.Data:MovePlayer(name, frame.listId, targetListId)
                RR.UI.MainWindow:Refresh()
            else
                -- Если в пустоту или в свою же колонку — просто перерисовываем, чтобы кнопка прыгнула обратно
                RR.UI.MainWindow:Refresh()
            end
        end)
        -- ==========================================

        table.insert(self.items, btn)
    end

    return frame
end
