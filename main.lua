local GlobalAddonName, AIU = ...

local AZPIUManaGementVersion = 4
local dash = " - "
local name = "InstanceUtility" .. dash .. "ManaGement"
local nameFull = ("AzerPUG " .. name)
local promo = (nameFull .. dash ..  AZPIUManaGementVersion)

local addonMain = LibStub("AceAddon-3.0"):NewAddon("InstanceUtility-ManaGement", "AceConsole-3.0")

local ModuleStats = AZP.IU.ModuleStats

local moveable = false
local raidHealers

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

    local AZPGVButton = CreateFrame("Button", nil, ModuleStats["Frames"]["ManaGement"], "UIPanelButtonTemplate")
    AZPGVButton.contentText = AZPGVButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    AZPGVButton.contentText:SetText("Toggle Bar Movement!")
    AZPGVButton:SetWidth("100")
    AZPGVButton:SetHeight("25")
    AZPGVButton.contentText:SetWidth("100")
    AZPGVButton.contentText:SetHeight("15")
    AZPGVButton:SetPoint("TOPLEFT", 25, -10)
    AZPGVButton.contentText:SetPoint("CENTER", 0, -1)
    AZPGVButton:SetScript("OnClick",
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

    addonMain:ResetManaBars()

    -- Change so that not current power but MANA is tracked.
    -- Add boss, if boss encounter.
    -- Update list to be ordered based on % HealerMana / BossHealth.
    -- Add Class Colors.
    -- Progression bar changes color based on %.
        -- Within 0 - 5% of boss health == Green.
        -- Within 5 - 10% of boss health == Yellow.
        -- Outisde of 10% of boss health == Red.
    -- Make healer mana % to boss health change color GRADIENT! (multiply % with RGB number).
end

function addonMain:TrackMana()
    for i=1,#raidHealers do
        raidHealers[i][6]:SetValue(UnitPower(raidHealers[i][5], 0))
        raidHealers[i][6].manaPercentText:SetText(math.floor(UnitPower(raidHealers[i][5], 0)/raidHealers[i][4]*100) .. "%")
    end
end

function addonMain:OrderManaBars()
    table.sort(raidHealers, function(a, b) 
        local percentA = math.floor(UnitPower(a[5], 0)/a[4]*100)
        local percentB = math.floor(UnitPower(b[5], 0)/b[4]*100)
        
        return percentA > percentB
    end)

    for i=1,#raidHealers do
        raidHealers[i][6]:SetPoint("CENTER", 0, -25*i)
    end
end

function addonMain:setScale(scale)
    ManaGementScale = scale
    for i=1,#raidHealers do
        raidHealers[i][6]:SetScale(scale)
    end
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
        raidHealers[i][6]:SetPoint("CENTER", 0, -25*i)
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