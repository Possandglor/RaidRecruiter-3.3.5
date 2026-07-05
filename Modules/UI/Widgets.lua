RaidRecruiter = RaidRecruiter or {}
local RR = RaidRecruiter
RR.UI = RR.UI or {} -- Инициализируем модуль UI если он еще не создан

-- Общий шаблон фона (Backdrop) для окон 3.3.5
RR.UI.BackdropTemplate = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
}

-- Фабрика для создания кнопок в едином стиле
function RR.UI:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 100, height or 22)
    btn:SetText(text)
    
    -- Скины кнопок в 3.3.5 иногда требуют явного обновления текстур
    local fontString = btn:GetFontString()
    if fontString then
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 11, "NONE")
    end
    
    return btn
end

-- Фабрика для поля ввода (EditBox)
function RR.UI:CreateEditBox(parent, width, height, titleText)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, height or 20)
    edit:SetAutoFocus(false)
    
    -- Очистка фокуса по клавише ESC
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    if titleText then
        local label = edit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", edit, "TOPLEFT", 0, 2)
        label:SetText(titleText)
    end
    
    return edit
end

-- Фабрика для галочки (CheckBox)
function RR.UI:CreateCheckBox(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    
    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    label:SetText(text)
    
    return cb
end

-- Фабрика для радио-кнопки (RadioButton)
function RR.UI:CreateRadioButton(parent, text)
    local rb = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    rb:SetSize(16, 16)
    
    local label = rb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    label:SetText(text)
    
    return rb
end