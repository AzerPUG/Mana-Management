if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end

AZP.VersionControl["Mana Management"] = 21
if AZP.ManaManagement == nil then AZP.ManaManagement = {} end
if AZP.ManaManagement.Events == nil then AZP.ManaManagement.Events = {} end

local AZPMMSelfOptionPanel = nil
local moveable = false
local raidHealers
local bossHealthBar
local optionHeader = "|cFF00FFFFMana Management|r"
local AZPManaGementFrame
local UpdateFrame = nil
local HaveShowedUpdateNotification = false
local InnervaterFrameEnabled, InnervateFrame = false, nil
local InnervateSpecIDs = {102, 105}
local DidHaveInnervate = false
local allFrames = {}
local OptionsFrame = nil
function AZP.ManaManagement:OnLoadBoth()
    if ManaGementScale == nil then
        ManaGementScale = 1.0
    end

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
    AZPManaGementFrame.healers = {}

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
    bossHealthBar.healthPercentText:SetPoint("RIGHT", -5, 0)
    bossHealthBar.healthPercentText:SetSize(50, 20)
    bossHealthBar.bossNameText = bossHealthBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    bossHealthBar.bossNameText:SetText("UnEngaged")
    bossHealthBar.bossNameText:SetPoint("LEFT", 5, 0)
    bossHealthBar.bossNameText:SetJustifyH("LEFT")
    bossHealthBar.bossNameText:SetSize(150, 20)
    bossHealthBar:SetStatusBarColor(0, 0.75, 1)
    bossHealthBar:SetScale(ManaGementScale)
    table.insert(allFrames, bossHealthBar)
    AZP.ManaManagement:ResetManaBars()
    AZP.ManaManagement:CreateCustomOptionFrame()
end

function AZP.ManaManagement:OnLoadCore()
    AZP.Core:RegisterEvents("UNIT_POWER_UPDATE", function(...) AZP.ManaManagement.Events:UnitPowerUpdate(...) end)
    AZP.Core:RegisterEvents("GROUP_ROSTER_UPDATE", function(...) AZP.ManaManagement.Events:GroupRosterUpdate(...) end)
    AZP.Core:RegisterEvents("VARIABLES_LOADED", function(...) AZP.ManaManagement.Events:VariablesLoadedManaBars(...) end)
    AZP.Core:RegisterEvents("PLAYER_SPECIALIZATION_CHANGED", function(...) AZP.ManaManagement.Events:PlayerSpecializationChanged(...) end)

    AZP.ManaManagement:OnLoadBoth()

    AZP.OptionsPanels:RemovePanel("Mana Management")
    AZP.OptionsPanels:Generic("Mana Management", optionHeader, function (frame)
        AZP.ManaManagement:FillOptionsPanel(frame)
    end)

end

function AZP.ManaManagement:OnLoadSelf()
    local EventFrame = CreateFrame("Frame")
    EventFrame:SetScript("OnEvent", function(...) AZP.ManaManagement:OnEvent(...) end)
    EventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    EventFrame:RegisterEvent("CHAT_MSG_ADDON")
    EventFrame:RegisterEvent("VARIABLES_LOADED")
    EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    AZPMMSelfOptionPanel = CreateFrame("FRAME", nil)
    AZPMMSelfOptionPanel.name = optionHeader
    InterfaceOptions_AddCategory(AZPMMSelfOptionPanel)
    AZPMMSelfOptionPanel.header = AZPMMSelfOptionPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    AZPMMSelfOptionPanel.header:SetPoint("TOP", 0, -10)
    AZPMMSelfOptionPanel.header:SetText("|cFF00FFFFAzerPUG's Mana Management Options!|r")

    AZPMMSelfOptionPanel.footer = AZPMMSelfOptionPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    AZPMMSelfOptionPanel.footer:SetPoint("TOP", 0, -300)
    AZPMMSelfOptionPanel.footer:SetText(
        "|cFF00FFFFAzerPUG Links:\n" ..
        "Website: www.azerpug.com\n" ..
        "Discord: www.azerpug.com/discord\n" ..
        "Twitch: www.twitch.tv/azerpug\n|r"
    )

    UpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    UpdateFrame:SetPoint("CENTER", 0, 250)
    UpdateFrame:SetSize(400, 200)
    UpdateFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    UpdateFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    UpdateFrame.header = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalHuge")
    UpdateFrame.header:SetPoint("TOP", 0, -10)
    UpdateFrame.header:SetText("|cFFFF0000AzerPUG Mana Management is out of date!|r")

    UpdateFrame.text = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalLarge")
    UpdateFrame.text:SetPoint("TOP", 0, -40)
    UpdateFrame.text:SetText("Error!")

    UpdateFrame:Hide()

    local UpdateFrameCloseButton = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    UpdateFrameCloseButton:SetWidth(25)
    UpdateFrameCloseButton:SetHeight(25)
    UpdateFrameCloseButton:SetPoint("TOPRIGHT", UpdateFrame, "TOPRIGHT", 2, 2)
    UpdateFrameCloseButton:SetScript("OnClick", function() UpdateFrame:Hide() end )

    AZP.ManaManagement:OnLoadBoth()
    AZP.ManaManagement:FillOptionsPanel(AZPMMSelfOptionPanel)
end

function AZP.ManaManagement:CreateCustomOptionFrame()
    OptionsFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    OptionsFrame:SetSize(300, 125)
    OptionsFrame:SetPoint("CENTER", 0, 0)
    OptionsFrame:EnableMouse(true)
    OptionsFrame:SetMovable(true)
    OptionsFrame:RegisterForDrag("LeftButton")
    OptionsFrame:SetScript("OnDragStart", OptionsFrame.StartMoving)
    OptionsFrame:SetScript("OnDragStop", function() OptionsFrame:StopMovingOrSizing() end)
    OptionsFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    OptionsFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.75)

    OptionsFrame.Header = OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    OptionsFrame.Header:SetSize(OptionsFrame:GetWidth(), 25)
    OptionsFrame.Header:SetPoint("TOP", 0, -5)
    OptionsFrame.Header:SetText(string.format("AzerPUG's Mana Management v%s", AZP.VersionControl["Mana Management"]))

    OptionsFrame.SubHeader = OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    OptionsFrame.SubHeader:SetSize(OptionsFrame:GetWidth(), 16)
    OptionsFrame.SubHeader:SetPoint("TOP", OptionsFrame.Header, "BOTTOM", 0, 0)
    OptionsFrame.SubHeader:SetText("Options Panel")

    OptionsFrame.CloseButton = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
    OptionsFrame.CloseButton:SetSize(20, 21)
    OptionsFrame.CloseButton:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", 2, 2)
    OptionsFrame.CloseButton:SetScript("OnClick", function() OptionsFrame:Hide() end)

    OptionsFrame.BGColorButton = CreateFrame("Button", nil, OptionsFrame, "UIPanelButtonTemplate")
    OptionsFrame.BGColorButton:SetSize(75, 20)
    OptionsFrame.BGColorButton:SetPoint("CENTER", 0, 0)
    OptionsFrame.BGColorButton:SetText("BG Color")
    OptionsFrame.BGColorButton:SetScript("OnClick", function() AZP.ManaManagement:ColorPickerMain(allFrames, "BG") end)
    ColorPickerOkayButton:HookScript("OnClick", function() AZP.ManaManagement:ColorSave() end)


    OptionsFrame.AZPMGShowHideButton = CreateFrame("Button", nil, OptionsFrame, "UIPanelButtonTemplate")
    OptionsFrame.AZPMGShowHideButton.contentText = OptionsFrame.AZPMGShowHideButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    OptionsFrame.AZPMGShowHideButton:SetWidth("100")
    OptionsFrame.AZPMGShowHideButton:SetHeight("25")
    OptionsFrame.AZPMGShowHideButton.contentText:SetWidth("100")
    OptionsFrame.AZPMGShowHideButton.contentText:SetHeight("15")
    OptionsFrame.AZPMGShowHideButton:SetPoint("RIGHT", OptionsFrame.BGColorButton, "LEFT", -5, 0)
    OptionsFrame.AZPMGShowHideButton.contentText:SetPoint("CENTER", 0, -1)
    OptionsFrame.AZPMGShowHideButton:SetScript("OnClick", function()
        if AZPManaGementFrame:IsShown() then
            AZPManaGementFrame:Hide()
            OptionsFrame.AZPMGShowHideButton.contentText:SetText("Show")
        else
            AZPManaGementFrame:Show()
            OptionsFrame.AZPMGShowHideButton.contentText:SetText("Hide")
        end
    end )

    if AZPManaGementFrame:IsShown() then
        OptionsFrame.AZPMGShowHideButton.contentText:SetText("Hide")
    else
        OptionsFrame.AZPMGShowHideButton.contentText:SetText("Show")
    end

    OptionsFrame.AZPMGToggleMoveButton = CreateFrame("Button", nil, OptionsFrame, "UIPanelButtonTemplate")
    OptionsFrame.AZPMGToggleMoveButton.contentText = OptionsFrame.AZPMGToggleMoveButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    OptionsFrame.AZPMGToggleMoveButton.contentText:SetText("Toggle Movement!")
    OptionsFrame.AZPMGToggleMoveButton:SetWidth("100")
    OptionsFrame.AZPMGToggleMoveButton:SetHeight("25")
    OptionsFrame.AZPMGToggleMoveButton.contentText:SetWidth("100")
    OptionsFrame.AZPMGToggleMoveButton.contentText:SetHeight("15")
    OptionsFrame.AZPMGToggleMoveButton:SetPoint("LEFT", OptionsFrame.BGColorButton, "RIGHT", 5, 0)
    OptionsFrame.AZPMGToggleMoveButton.contentText:SetPoint("CENTER", 0, -1)
    OptionsFrame.AZPMGToggleMoveButton:SetScript("OnClick",
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


    OptionsFrame.ManaGementScaleSlider = CreateFrame("SLIDER", "ManaGementScaleSlider", OptionsFrame, "OptionsSliderTemplate")
    OptionsFrame.ManaGementScaleSlider:SetHeight(20)
    OptionsFrame.ManaGementScaleSlider:SetWidth(200)
    OptionsFrame.ManaGementScaleSlider:SetOrientation('HORIZONTAL')
    OptionsFrame.ManaGementScaleSlider:SetPoint("TOP", OptionsFrame.BGColorButton, "BOTTOM", 0, -20)
    OptionsFrame.ManaGementScaleSlider:EnableMouse(true)
    OptionsFrame.ManaGementScaleSlider.tooltipText = 'Scale for mana bars'
    ManaGementScaleSliderLow:SetText('small')
    ManaGementScaleSliderHigh:SetText('big')
    ManaGementScaleSliderText:SetText('Scale')

    OptionsFrame.ManaGementScaleSlider:Show()
    OptionsFrame.ManaGementScaleSlider:SetMinMaxValues(0.5, 2)
    OptionsFrame.ManaGementScaleSlider:SetValueStep(0.1)

    OptionsFrame.ManaGementScaleSlider:SetScript("OnValueChanged", AZP.ManaManagement.setScale)

    -- OptionsFrame.TextColorButton = CreateFrame("Button", nil, OptionsFrame, "UIPanelButtonTemplate")
    -- OptionsFrame.TextColorButton:SetSize(75, 20)
    -- OptionsFrame.TextColorButton:SetPoint("LEFT", OptionsFrame.BorderColorButton, "RIGHT", 5, 0)
    -- OptionsFrame.TextColorButton:SetText("Text Color")
    -- OptionsFrame.TextColorButton:SetScript("OnClick", function() AZPMMColorPickerMain(allTextParts, "Text") end)
    OptionsFrame:Hide()
end

function AZP.ManaManagement.Events:PlayerSpecializationChanged(unitID)
    if unitID == "player" and ((DidHaveInnervate and not AZP.ManaManagement:HasInnervate()) or (not DidHaveInnervate and AZP.ManaManagement:HasInnervate()))  then
        for _, section in ipairs(AZPManaGementFrame.healers) do
            section.frame:Hide()
            section.frame.manabar:Hide()
        end
        AZPManaGementFrame.healers = {}
    end
    AZP.ManaManagement:ResetManaBars()
end

function  AZP.ManaManagement:ResetManaBars()
    if AZP.ManaManagement:HasInnervate() and UnitAffectingCombat("PLAYER") then
        return
    end

    DidHaveInnervate = AZP.ManaManagement:HasInnervate()

    raidHealers = {}

    for _, section in ipairs(AZPManaGementFrame.healers) do
        section.frame:Hide()
        section.frame.manabar:Hide()
    end

    if IsInGroup() then
        if IsInRaid() then
            for i=1, GetNumGroupMembers() do
                AZP.ManaManagement:AddPlayerIfHealer(string.format("raid%d", i))
            end
        else
            for i=1, GetNumGroupMembers() do
                AZP.ManaManagement:AddPlayerIfHealer(string.format("party%d", i))
            end
            AZP.ManaManagement:AddPlayerIfHealer("player")
        end
    end

    local spellname = GetSpellInfo(29166)
    for i, healer in ipairs(raidHealers) do
        local healerSection = AZPManaGementFrame.healers[i]
        if healerSection == nil then
            healerSection = {}

            if AZP.ManaManagement:HasInnervate() then
                healerSection.frame = CreateFrame("Button", nil, AZPManaGementFrame, "SecureActionButtonTemplate")
                healerSection.frame:SetSize(150, 25)
                healerSection.frame:SetPoint("CENTER", 0, -25*i-25)
                healerSection.frame:SetAttribute("type", "spell")
                healerSection.frame:SetAttribute("spell", spellname)
                healerSection.frame:SetAttribute("unit", healer[1])
                healerSection.frame:SetScale(ManaGementScale)
            else
                healerSection.frame = CreateFrame("Frame", nil, AZPManaGementFrame)
            end
            healerSection.frame.manabar = CreateFrame("StatusBar", nil, AZPManaGementFrame)
            healerSection.frame.manabar.manaPercentText = healerSection.frame.manabar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            healerSection.frame.manabar.healerNameText = healerSection.frame.manabar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            healerSection.frame.manabar.bg = healerSection.frame.manabar:CreateTexture(nil, "BACKGROUND")
            AZPManaGementFrame.healers[i] = healerSection
            table.insert(allFrames, healerSection.frame.manabar)
        end

        healer[6] = healerSection
        healerSection.name = healer[1]
        healerSection.frame.manabar:SetSize(150, 25)
        healerSection.frame.manabar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        healerSection.frame.manabar:SetMinMaxValues(0, healer[4])
        healerSection.frame.manabar:SetValue(healer[3])
        healerSection.frame.manabar:SetPoint("CENTER", 0, -25*i-25)
        healerSection.frame.manabar:SetScale(ManaGementScale)
        healerSection.frame.manabar.bg = healerSection.frame.manabar:CreateTexture(nil, "BACKGROUND")
        healerSection.frame.manabar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        healerSection.frame.manabar.bg:SetAllPoints(true)
        healerSection.frame.manabar.bg:SetVertexColor(1, 0, 0)
        healerSection.frame.manabar.manaPercentText:SetText(math.floor(healer[3]/healer[4]*100))
        healerSection.frame.manabar.manaPercentText:SetPoint("RIGHT", -5, 0)
        healerSection.frame.manabar.manaPercentText:SetSize(50, 20)
        healerSection.frame.manabar.healerNameText:SetText(healer[1])
        healerSection.frame.manabar.healerNameText:SetPoint("LEFT", 5, 0)
        healerSection.frame.manabar.healerNameText:SetJustifyH("LEFT")
        healerSection.frame.manabar.healerNameText:SetSize(150, 20)
        healerSection.frame.manabar:SetStatusBarColor(0, 0.75, 1)
        healerSection.frame.manabar:Show()
        healerSection.frame:Show()
    end
end

function AZP.ManaManagement:HasInnervate() 
    local _, _, classIndex = UnitClass("player")
    local specIndex = GetSpecialization()
    local specID = GetSpecializationInfoForClassID(classIndex, specIndex)
    return tContains(InnervateSpecIDs, specID)
end

function AZP.ManaManagement.Events:VariablesLoaded(...)
    if AZPMMVars == nil then AZPMMVars = {} end

    if AZPMMLocation == nil then
        AZPMMLocation = {"CENTER", nil, nil, 200, 0}
    end
    AZPManaGementFrame:SetPoint(ManaGementLocation[1], ManaGementLocation[2], ManaGementLocation[3])
    AZP.ManaManagement:ColorLoad()
    AZP.ManaManagement:ResetManaBars()

end

function AZP.ManaManagement.Events:VariablesLoadedManaBars(...)
    bossHealthBar:SetScale(ManaGementScale)
    ManaGementScaleSlider:SetValue(ManaGementScale)
end

function AZP.ManaManagement:FillOptionsPanel(frameToFill)
    frameToFill.BGColorButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    frameToFill.BGColorButton:SetSize(75, 20)
    frameToFill.BGColorButton:SetPoint("CENTER", 0, 0)
    frameToFill.BGColorButton:SetText("Configure")
    frameToFill.BGColorButton:SetScript("OnClick", function() OptionsFrame:Show() InterfaceOptionsFrame:Hide() end)

    frameToFill:Hide()
end

function AZP.ManaManagement:ShareVersion()
    local versionString = string.format("|MM:%d|", AZP.VersionControl["Mana Management"])
    if UnitInBattleground("player") ~= nil then
        -- BG stuff?
    else
        if IsInGroup() then
            if IsInRaid() then
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"RAID", 1)
            else
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"PARTY", 1)
            end
        end
        if IsInGuild() then
            C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"GUILD", 1)
        end
    end
end

function AZP.ManaManagement:ReceiveVersion(version)
    if version > AZP.VersionControl["Mana Management"] then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            UpdateFrame:Show()
            UpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" .. 
                "Newer Version: v" .. version .. "\n" .. 
                "Your version: v" .. AZP.VersionControl["Mana Management"]
            )
        end
    end
end

function AZP.ManaManagement:GetSpecificAddonVersion(versionString, addonWanted)
    local pattern = "|([A-Z]+):([0-9]+)|"
    local index = 1
    while index < #versionString do
        local _, endPos = string.find(versionString, pattern, index)
        local addon, version = string.match(versionString, pattern, index)
        index = endPos + 1
        if addon == addonWanted then
            return tonumber(version)
        end
    end
end

function AZP.ManaManagement:TrackMana()
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

    if raidHealers ~= nil then 
        for _,healer in ipairs(raidHealers) do
            healer[6].frame.manabar:SetValue(UnitPower(healer[5], 0))
            healer[6].frame.manabar.manaPercentText:SetText(math.floor(UnitPower(healer[5], 0)/healer[4]*100) .. "%")
            healer[6].frame.manabar.healerNameText:SetTextColor(AZP.ManaManagement:GetClassColor(healer[2]))
        end
    end
end

function AZP.ManaManagement:CalcPercent()   -- Unused function? Beginning of changes to calculate % even when not in combat?
end

function AZP.ManaManagement:OrderManaBars()
    table.sort(raidHealers, function(a, b)
        local percentA = math.floor(UnitPower(a[5], 0)/a[4]*100)
        local percentB = math.floor(UnitPower(b[5], 0)/b[4]*100)

        return percentA > percentB
    end)

    for i,healer in ipairs(raidHealers) do
        local healerFrame = healer[6].frame
        healerFrame:SetPoint("CENTER", 0, -25*i-25)
        healerFrame.manabar:SetPoint("CENTER", 0, -25*i-25)

        -- healer[6].InnervateButton:SetPoint(healer[6]:GetPoint())
    end
end

function  AZP.ManaManagement:setScale(scale)
    ManaGementScale = scale
    for _,healerSection in ipairs(AZPManaGementFrame.healers) do
        healerSection.frame:SetScale(scale)
        --healer[7]:SetScale(scale)
    end
    bossHealthBar:SetScale(scale)
end

function AZP.ManaManagement:AddPlayerIfHealer(target)
    local unitRole = UnitGroupRolesAssigned(target)
    if unitRole == "HEALER" then
        local newHealerIndex = #raidHealers + 1
        raidHealers[newHealerIndex] = {}
        raidHealers[newHealerIndex][1] = UnitName(target)
        _, _, raidHealers[newHealerIndex][2] = UnitClass(target)
        raidHealers[newHealerIndex][3] = UnitPower(target, 0)
        raidHealers[newHealerIndex][4] = UnitPowerMax(target, 0)
        raidHealers[newHealerIndex][5] = target
    end
end

function AZP.ManaManagement:GetInnervateTarget(healerName)
    local target, targetName
    if IsInGroup() then
        if IsInRaid() then
            for i=1,GetNumGroupMembers() do
                target = string.format("raid%d", i)
                targetName = UnitName(target)
                if healerName == targetName then
                    return target
                end
            end
        else
            for i=1,GetNumGroupMembers()-1 do
                target = string.format("party%d", i)
                targetName = UnitName(target)
                if healerName == targetName then
                    return target
                end
            end
            target = "player"
            targetName = UnitName(target)
            if healerName == targetName then
                return target
            end
        end
    end

    for i = 1, 40 do
        if GetRaidRosterInfo(i) ~= nil then
            local raiderName = GetRaidRosterInfo(i)
            if healerName == raiderName then
                return ("raid" .. i)
            end
        end
    end
end

function AZP.ManaManagement:GetClassColor(classIndex)       -- https://wowpedia.fandom.com/wiki/API_GetClassColor
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

function AZP.ManaManagement.Events:UnitPowerUpdate(...)
    local unitID, powerID = ...
    if powerID == "MANA" then
        if UnitGroupRolesAssigned(unitID) == "HEALER" then
            AZP.ManaManagement:TrackMana()
            if AZP.ManaManagement:HasInnervate() == false then
                AZP.ManaManagement:OrderManaBars()
            end
        end
    end
end

function AZP.ManaManagement.Events:ChatMsgAddon(...)
    local prefix, payload, _, sender = ...
    if prefix == "AZPVERSIONS" then
        local version = AZP.ManaManagement:GetSpecificAddonVersion(payload, "MM")
        if version ~= nil then
            AZP.ManaManagement:ReceiveVersion(version)
        end
    end
end

function AZP.ManaManagement.Events:GroupRosterUpdate(...)
    AZP.ManaManagement:ResetManaBars()
    if not IsAddOnLoaded("AzerPUGsCore") then
        AZP.ManaManagement:ShareVersion()
    end
end

function AZP.ManaManagement:ColorPickerMain(Frames, Component)
    ColorPickerFrameInUse = Component
    local r, g, b, a = nil, nil, nil, nil
        if Component == "BG" then r, g, b, a = Frames[1]:GetStatusBarColor()
    elseif Component == "Text" then r, g, b, a = Frames[1]:GetTextColor() end
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
    ColorPickerFrame.previousValues = {r,g,b,a}
    ColorPickerFrame:SetColorRGB(r,g,b)

    ColorPickerFrame.func = function() AZP.ManaManagement:ColorPickerAcceptFunction(Frames, Component) end
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function(prev) AZP.ManaManagement:ColorPickerCancelFunction(Frames, Component, prev) end

    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

function AZP.ManaManagement:ColorLoad()
    if AZPMMVars.BG ~= nil then
        AZP.ManaManagement:SetColorForFrames(allFrames, AZPMMVars.BG, "BG")
    end
end

function AZP.ManaManagement:ColorSave()
    if ColorPickerFrameInUse ~= nil then
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = OpacitySliderFrame:GetValue()
        AZPMMVars[ColorPickerFrameInUse] = {r, g, b, a}
        ColorPickerFrameInUse = nil
    end
end

function AZP.ManaManagement:ColorPickerAcceptFunction(Frames, Component)
    local r, g, b = ColorPickerFrame:GetColorRGB()
    local a = OpacitySliderFrame:GetValue()
    AZP.ManaManagement:SetColorForFrames(Frames, {r, g, b, a}, Component)
end

function AZP.ManaManagement:ColorPickerCancelFunction(Frames, Component, prev)
    ColorPickerFrameInUse = nil
    AZP.ManaManagement:SetColorForFrames(Frames, prev, Component)
end

function AZP.ManaManagement:SetColorForFrames(Frames, Color, Component)
    local r, g, b, a = unpack(Color)
    for _, curFrame in pairs(Frames) do
        if Component == "BG" then curFrame:SetStatusBarColor(r, g, b)
    elseif Component == "Text" then curFrame:SetTextColor(r, g, b, a) end
    end
end


function AZP.ManaManagement:OnEvent(self, event, ...)
    if event == "UNIT_POWER_UPDATE" then
        AZP.ManaManagement.Events:UnitPowerUpdate(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        AZP.ManaManagement.Events:GroupRosterUpdate(...)
    elseif event == "CHAT_MSG_ADDON" then
        AZP.ManaManagement.Events:ChatMsgAddon(...)
    elseif event == "VARIABLES_LOADED" then
        AZP.ManaManagement.Events:VariablesLoaded(...)
        AZP.ManaManagement.Events:VariablesLoadedManaBars(...)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        AZP.ManaManagement.Events:PlayerSpecializationChanged(...)
    end
end

if not IsAddOnLoaded("AzerPUGsCore") then
    AZP.ManaManagement:OnLoadSelf()
end

AZP.SlashCommands["MM"] = function()
    OptionsFrame:Show()
end

AZP.SlashCommands["mm"] = AZP.SlashCommands["MM"]
AZP.SlashCommands["mana"] = AZP.SlashCommands["MM"]
AZP.SlashCommands["mana management"] = AZP.SlashCommands["MM"]
