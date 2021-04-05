local GlobalAddonName, AIU = ...

local AZPIUManaGementVersion = 10
local dash = " - "
local name = "InstanceUtility" .. dash .. "ManaGement"
local nameFull = ("AzerPUG " .. name)
local promo = (nameFull .. dash ..  AZPIUManaGementVersion)

local addonMain = LibStub("AceAddon-3.0"):NewAddon("InstanceUtility-ManaGement", "AceConsole-3.0")

local ModuleStats = AZP.IU.ModuleStats

local moveable = false
local raidHealers
local bossHealthBar

function AZP.IU.VersionControl:ManaGement()
    return AZPIUManaGementVersion
end

function AZP.IU.OnLoad:ManaGement(self)
    -- Default scale, 1.
    if ManaGementScale == nil then
        ManaGementScale = 1.0
    end

    ModuleStats["Frames"]["ManaGement"]:SetSize(200, 100)
    addonMain:ChangeOptionsText()
    InstanceUtilityAddonFrame:RegisterEvent("UNIT_POWER_UPDATE")
    InstanceUtilityAddonFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    AZPManaGementFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    AZPManaGementFrame:SetWidth("200")
    AZPManaGementFrame:SetHeight("50")
    if ManaGementLocation == nil then
        AZPManaGementFrame:SetPoint("CENTER", -300, 200)
    else
        AZPManaGementFrame:SetPoint(ManaGementLocation[1], ManaGementLocation[2], ManaGementLocation[3])
    end
    AZPManaGementFrame:SetScript("OnDragStart", AZPManaGementFrame.StartMoving)
    AZPManaGementFrame:SetScript("OnDragStop", AZPManaGementFrame.StopMovingOrSizing)

    local AZPMGShowHideButton = CreateFrame("Button", nil, ModuleStats["Frames"]["ManaGement"], "UIPanelButtonTemplate")
    AZPMGShowHideButton.contentText = AZPMGShowHideButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    if AZPManaGementFrame:IsShown() then
        AZPMGShowHideButton.contentText:SetText("Hide")
    else
        AZPMGShowHideButton.contentText:SetText("Show")
    end
    AZPMGShowHideButton:SetWidth("100")
    AZPMGShowHideButton:SetHeight("25")
    AZPMGShowHideButton.contentText:SetWidth("100")
    AZPMGShowHideButton.contentText:SetHeight("15")
    AZPMGShowHideButton:SetPoint("TOPLEFT", 25, -35)
    AZPMGShowHideButton.contentText:SetPoint("CENTER", 0, -1)
    AZPMGShowHideButton:SetScript("OnClick", function()
        if AZPManaGementFrame:IsShown() then
            AZPManaGementFrame:Hide()
            AZPMGShowHideButton.contentText:SetText("Show")
        else
            AZPManaGementFrame:Show()
            AZPMGShowHideButton.contentText:SetText("Hide")
        end
    end )
    
    local AZPMGToggleMoveButton = CreateFrame("Button", nil, ModuleStats["Frames"]["ManaGement"], "UIPanelButtonTemplate")
    AZPMGToggleMoveButton.contentText = AZPMGToggleMoveButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    AZPMGToggleMoveButton.contentText:SetText("Toggle Movement!")
    AZPMGToggleMoveButton:SetWidth("100")
    AZPMGToggleMoveButton:SetHeight("25")
    AZPMGToggleMoveButton.contentText:SetWidth("100")
    AZPMGToggleMoveButton.contentText:SetHeight("15")
    AZPMGToggleMoveButton:SetPoint("TOPLEFT", 25, -10)
    AZPMGToggleMoveButton.contentText:SetPoint("CENTER", 0, -1)
    AZPMGToggleMoveButton:SetScript("OnClick",
    function()
        if moveable == false then
            AZPManaGementFrame:SetMovable(true)
            AZPManaGementFrame:EnableMouse(true)
            AZPManaGementFrame:RegisterForDrag("LeftButton")
            AZPManaGementFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 12,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            AZPManaGementFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.75)
            moveable = true
        else
            AZPManaGementFrame:SetMovable(false)
            AZPManaGementFrame:EnableMouse(false)
            AZPManaGementFrame:RegisterForDrag()
            AZPManaGementFrame:SetBackdrop({
                bgFile = nil,
                edgeFile = nil,
                edgeSize = nil,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            AZPManaGementFrame:SetBackdropColor(0, 0, 0, 0)
            local x1, x2, x3, x4, x5 = AZPManaGementFrame:GetPoint()
            ManaGementLocation = {x1, x4, x5}
            moveable = false
        end
    end)

    bossHealthBar = CreateFrame("StatusBar", nil, AZPManaGementFrame)
    bossHealthBar:SetSize(150, 25)
    bossHealthBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bossHealthBar:SetPoint("CENTER", 0, -25)
    bossHealthBar:SetMinMaxValues(0, 100)
    bossHealthBar:SetValue(100)
    bossHealthBar.bg = bossHealthBar:CreateTexture(nil, "BACKGROUND")
    bossHealthBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bossHealthBar.bg:SetAllPoints(true)
    bossHealthBar.bg:SetVertexColor(1, 0, 0)
    bossHealthBar.healthPercentText = bossHealthBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    bossHealthBar.healthPercentText:SetText("N/A")
    bossHealthBar.healthPercentText:SetPoint("CENTER", 25, 0)
    bossHealthBar.healthPercentText:SetSize(150, 20)
    bossHealthBar.bossNameText = bossHealthBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    bossHealthBar.bossNameText:SetText("UnEngaged")
    bossHealthBar.bossNameText:SetPoint("LEFT", 5, 0)
    bossHealthBar.bossNameText:SetJustifyH("LEFT")
    bossHealthBar.bossNameText:SetSize(150, 20)
    bossHealthBar:SetStatusBarColor(0, 0.75, 1)
    bossHealthBar:SetScale(ManaGementScale)



    addonMain:ResetManaBars()
end

function addonMain:TrackMana()
    local bossName = UnitName("boss1")
    local bossMaxHealth = UnitHealthMax("boss1")
    local bossCurrentHealth = UnitHealth("boss1")

    if bossName ~= nil then
        bossHealthBar.bossNameText:SetText("Boss")
        bossHealthBar:SetMinMaxValues(0, bossMaxHealth)
        bossHealthBar:SetValue(bossCurrentHealth)
        bossHealthBar.healthPercentText:SetText(math.floor(bossCurrentHealth/bossMaxHealth*100) .. "%")
    else
        bossHealthBar.bossNameText:SetText("UnEngaged")
        bossHealthBar:SetMinMaxValues(0, 100)
        bossHealthBar:SetValue(100)
        bossHealthBar.healthPercentText:SetText("N/A")
    end

    for i=1,#raidHealers do
        raidHealers[i][6]:SetValue(UnitPower(raidHealers[i][5], 0))
        raidHealers[i][6].manaPercentText:SetText(math.floor(UnitPower(raidHealers[i][5], 0)/raidHealers[i][4]*100) .. "%")

        raidHealers[i][6].healerNameText:SetTextColor(addonMain:GetClassColor(raidHealers[i][2]))
    end
end

function addonMain:CalcPercent()

end

function addonMain:OrderManaBars()
    table.sort(raidHealers, function(a, b)
        local percentA = math.floor(UnitPower(a[5], 0)/a[4]*100)
        local percentB = math.floor(UnitPower(b[5], 0)/b[4]*100)

        return percentA > percentB
    end)

    for i=1,#raidHealers do
        raidHealers[i][6]:SetPoint("CENTER", 0, -25*i-25)
    end
end

function addonMain:setScale(scale)
    ManaGementScale = scale
    for i=1,#raidHealers do
        raidHealers[i][6]:SetScale(scale)
    end
    bossHealthBar:SetScale(scale)
end

function addonMain:ResetManaBars()
    if raidHealers ~= nil then
        for i=1,#raidHealers do
            raidHealers[i][6].contentText = nil
            raidHealers[i][6].manaPercentText = nil
            raidHealers[i][6]:Hide()
            raidHealers[i][6]:SetParent(nil)
        end
    end

    raidHealers = {}

    for i=1,GetNumGroupMembers() do
        local raidUnitID = string.format("raid%d", i)
        local unitRole = UnitGroupRolesAssigned(raidUnitID)
        if unitRole == "HEALER" then
            local newHealerIndex = #raidHealers + 1
            raidHealers[newHealerIndex] = {}
            raidHealers[newHealerIndex][1] = UnitName(raidUnitID)
            _, _, raidHealers[newHealerIndex][2] = UnitClass(raidUnitID);
            raidHealers[newHealerIndex][3] = UnitPower(raidUnitID, 0)
            raidHealers[newHealerIndex][4] = UnitPowerMax(raidUnitID, 0)
            raidHealers[newHealerIndex][5] = raidUnitID
        end
    end

    for i=1,#raidHealers do
        raidHealers[i][6] = CreateFrame("StatusBar", nil, AZPManaGementFrame)
        raidHealers[i][6]:SetSize(150, 25)
        raidHealers[i][6]:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        raidHealers[i][6]:SetMinMaxValues(0, raidHealers[i][4])
        raidHealers[i][6]:SetValue(raidHealers[i][3])
        raidHealers[i][6]:SetPoint("CENTER", 0, -25*i-25)
        raidHealers[i][6]:SetScale(ManaGementScale)
        raidHealers[i][6].bg = raidHealers[i][6]:CreateTexture(nil, "BACKGROUND")
        raidHealers[i][6].bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        raidHealers[i][6].bg:SetAllPoints(true)
        raidHealers[i][6].bg:SetVertexColor(1, 0, 0)
        raidHealers[i][6].manaPercentText = raidHealers[i][6]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        raidHealers[i][6].manaPercentText:SetText(math.floor(raidHealers[i][3]/raidHealers[i][4]*100))
        raidHealers[i][6].manaPercentText:SetPoint("CENTER", 25, 0)
        raidHealers[i][6].manaPercentText:SetSize(150, 20)
        raidHealers[i][6].healerNameText = raidHealers[i][6]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        raidHealers[i][6].healerNameText:SetText(raidHealers[i][1])
        raidHealers[i][6].healerNameText:SetPoint("LEFT", 5, 0)
        raidHealers[i][6].healerNameText:SetJustifyH("LEFT")
        raidHealers[i][6].healerNameText:SetSize(150, 20)
        raidHealers[i][6]:SetStatusBarColor(0, 0.75, 1)
    end
end

function addonMain:GetClassColor(classIndex)
    if classIndex ==  0 then return 0.00, 0.00, 0.00          -- None
    elseif classIndex ==  1 then return 0.78, 0.61, 0.43      -- Warrior
    elseif classIndex ==  2 then return 0.96, 0.55, 0.73      -- Paladin
    elseif classIndex ==  3 then return 0.67, 0.83, 0.45      -- Hunter
    elseif classIndex ==  4 then return 1.00, 0.96, 0.41      -- Rogue
    elseif classIndex ==  5 then return 1.00, 1.00, 1.00      -- Priest
    elseif classIndex ==  6 then return 0.77, 0.12, 0.23      -- Death Knight
    elseif classIndex ==  7 then return 0.00, 0.44, 0.87      -- Shaman
    elseif classIndex ==  8 then return 0.25, 0.78, 0.92      -- Mage
    elseif classIndex ==  9 then return 0.53, 0.53, 0.93      -- Warlock
    elseif classIndex == 10 then return 0.00, 1.00, 0.60      -- Monk
    elseif classIndex == 11 then return 1.00, 0.49, 0.04      -- Druid
    elseif classIndex == 12 then return 0.64, 0.19, 0.79      -- Demon Hunter
    end
end

function AZP.IU.OnEvent:ManaGement(event, ...)
    if event == "UNIT_POWER_UPDATE" then
        local unitID, powerID = ...
        if powerID == "MANA" then
            if UnitGroupRolesAssigned(unitID) == "HEALER" then
                addonMain:TrackMana()
                addonMain:OrderManaBars()
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        addonMain:ResetManaBars()
    end
end

function addonMain:ChangeOptionsText()
    ManaGementSubPanelPHTitle:Hide()
    ManaGementSubPanelPHText:Hide()
    ManaGementSubPanelPHTitle:SetParent(nil)
    ManaGementSubPanelPHText:SetParent(nil)

    local ManaGementSubPanelHeader = ManaGementSubPanel:CreateFontString("ManaGementSubPanelHeader", "ARTWORK", "GameFontNormalHuge")
    ManaGementSubPanelHeader:SetText(promo)
    ManaGementSubPanelHeader:SetWidth(ManaGementSubPanel:GetWidth())
    ManaGementSubPanelHeader:SetHeight(ManaGementSubPanel:GetHeight())
    ManaGementSubPanelHeader:SetPoint("TOP", 0, -10)

    local ManaGementSubPanelText = ManaGementSubPanel:CreateFontString("ManaGementSubPanelText", "ARTWORK", "GameFontNormalLarge")
    ManaGementSubPanelText:SetWidth(ManaGementSubPanel:GetWidth())
    ManaGementSubPanelText:SetHeight(ManaGementSubPanel:GetHeight())
    ManaGementSubPanelText:SetPoint("TOPLEFT", 0, -50)
    ManaGementSubPanelText:SetText(
        "For feature requests visit our Discord Server!"
    )
    
    local ManaGementScaleSlider = CreateFrame("SLIDER", "ManaGementScaleSlider", ManaGementSubPanel, "OptionsSliderTemplate")
    ManaGementScaleSlider:SetHeight(20)
    ManaGementScaleSlider:SetWidth(500)
    ManaGementScaleSlider:SetOrientation('HORIZONTAL')
    ManaGementScaleSlider:SetPoint("TOP", 0, -100)
    ManaGementScaleSlider:EnableMouse(true)
    ManaGementScaleSlider.tooltipText = 'Scale for mana bars'
    ManaGementScaleSliderLow:SetText('small')
    ManaGementScaleSliderHigh:SetText('big')
    ManaGementScaleSliderText:SetText('Scale')

    ManaGementScaleSlider:Show()
    ManaGementScaleSlider:SetMinMaxValues(0.5, 2)
    ManaGementScaleSlider:SetValueStep(0.1)
    ManaGementScaleSlider:SetValue(ManaGementScale)

    ManaGementScaleSlider:SetScript("OnValueChanged", addonMain.setScale)
end