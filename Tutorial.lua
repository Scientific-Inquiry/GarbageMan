local GARBAGEMAN_TUTORIAL1 = "|cFF9900ccFilter Button|r is a toggle that greys out items that will |cFFFF0000not|r be |cFFffcc00sold/|r|cFFFF0000deleted|r when |cFF42d9f4clicking|r the |cFF9900ccGarbage Button|r."
local GARBAGEMAN_TUTORIAL2 = "|cFF9900ccSell Button|r sells all garbage items in inventory. Items marked with a |cFFffcc00coin|r will be |cFFffcc00sold|r, and items |cFFFF0000colored red|r will be |cFFFF0000deleted|r. Use slash command |cFF42d9f4/gm|r to edit ".. 
	"|cFF42d9f4settings|r."
local GARBAGEMAN_TUTORIAL3 = "|cFF9900ccWhiteList|r items will |cFFFF0000not|r be |cFFffcc00sold|r when |cFF42d9f4clicking|r the |cFF9900ccSell Button|r. To add an item to the WhiteList, |cFF42d9f4Left-Click|r an inventory item while the WhiteList tab is |cFF42d9f4selected|r."
local GARBAGEMAN_TUTORIAL4 = "|cFF9900ccBlackList|r items will be |cFFffcc00sold/|r|cFFFF0000deleted|r when |cFF42d9f4clicking|r the |cFF9900ccSell Button|r. To add an item to the BlackList, |cFF42d9f4Left-Click|r an inventory item while the BlackList tab is |cFF42d9f4selected|r."
local GARBAGEMAN_TUTORIAL5 = "The DropDownMenu switches between Account-wide and Characer-specific |cFF9900ccWhitelist/BlackList|r to view/add items"

local GARBAGEMAN_HELP_BANK_TOOLTIP = "|cFFFF0000Red|r items are considered Garbage. |cFF42d9f4Click|r to edit settings."
local GARBAGEMAN_HELP_BUTTON_TOOLTIP = "Click this to toggle on/off the help system for GarbageMan."

local MFwidth = MerchantFrame:GetWidth()
local MFheight = MerchantFrame:GetHeight()

--setting postion of tutorial panel
GarbageMan.HelpPlate = {
	FramePos = { x = 0,	y = -25 },
	FrameSize = { width = MFwidth, height = MFheight + 10}
}

--Purpose: Creates and initializes tutorial
--Returns: Nothing
function GarbageMan.generate_Tutorial()
	GarbageMan.tutorialButton = CreateFrame("Button", GarbageMan.name.."HelpButton", MerchantFrame, "GarbageManTutorialButtonTemplate")
	GarbageMan.tutorialButton:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 30, 20)
	GarbageMan.tutorialButton:Show()
	GarbageMan.tutorialButton:SetText(MAIN_HELP_BUTTON_TOOLTIP)

	GarbageMan.bankTutorialButton = CreateFrame("Button", GarbageMan.name.."BankHelpButton", BankFrame, "GarbageManTutorialButtonTemplate")
	GarbageMan.bankTutorialButton:SetPoint("TOPLEFT", BankFrame, "TOPLEFT", 30, 20)
	GarbageMan.bankTutorialButton:Show()
	GarbageMan.bankTutorialButton:SetText(MAIN_HELP_BUTTON_TOOLTIP)
	GarbageMan.bankTutorialButton:SetScript("OnClick", function(self) InterfaceOptionsFrame_OpenToCategory("GarbageMan") InterfaceOptionsFrame_OpenToCategory("GarbageMan")end)
end

--Purpose: Positions the filter tooltip based on Merchant window ui elements
--Returns: Nothing
function GarbageMan.PositionFilterTooltip()
	local currencies = { GetMerchantCurrencies() }
	local numCurrencies = #currencies
	if(numCurrencies >=1) then
		GarbageMan.HelpPlate[1] = { ButtonPos = { x = 100,	y = 5 }, HighLightBox = { x = 139, y = -4, width = 30, height = 30 },	ToolTipDir = "DOWN",	ToolTipText = GARBAGEMAN_TUTORIAL1 }
	else
		GarbageMan.HelpPlate[1] = { ButtonPos = { x = 90,	y = -380 }, HighLightBox = { x = 134, y = -391, width = 30, height = 30 },	ToolTipDir = "DOWN",	ToolTipText = GARBAGEMAN_TUTORIAL1 }
	end
end

--Purpose: Positions the sell button tooltip based on Merchant window ui elements
--Returns: Nothing
function GarbageMan.PositionGarbageButtonTooltip()
	if(MerchantRepairItemButton:IsShown() and MerchantGuildBankRepairButton:IsShown()) then 
		GarbageMan.HelpPlate[2] = { ButtonPos = { x = -5,	y = -320 }, HighLightBox = { x = -1, y = -357, width = 35, height = 35},		ToolTipDir = "RIGHT",		ToolTipText = GARBAGEMAN_TUTORIAL2 }
	elseif(MerchantRepairItemButton:IsShown() and not MerchantGuildBankRepairButton:IsShown()) then
		GarbageMan.HelpPlate[2] = { ButtonPos = { x = 45,	y = -315 }, HighLightBox = { x = 50, y = -352, width = 35, height = 35},		ToolTipDir = "RIGHT",		ToolTipText = GARBAGEMAN_TUTORIAL2 }
	else
		GarbageMan.HelpPlate[2] = { ButtonPos = { x = 80,	y = -340 }, HighLightBox = { x = 123, y = -349, width = 35, height = 35},		ToolTipDir = "UP",		ToolTipText = GARBAGEMAN_TUTORIAL2 }
	end
end

--Purpose: Toggles the tutorial system on/off and displays tutorial based on page
--Returns: Nothing
function GarbageMan.ToggleTutorial()
	local helpPlate = GarbageMan.HelpPlate;

	if (MerchantFrame:IsShown() and MerchantFrame.selectedTab == 3 and  not HelpPlate_IsShowing(GarbageMan.HelpPlate) ) then
		GarbageMan.HelpPlate[1] = { ButtonPos = { x = 65,	y = -380 }, HighLightBox = { x = 104, y = -391, width = 30, height = 30 },	ToolTipDir = "DOWN",	ToolTipText = GARBAGEMAN_TUTORIAL1 }
		GarbageMan.HelpPlate[2] = { ButtonPos = { x = 128,	y = 0 }, HighLightBox = { x = 58, y = -10, width = 96, height = 30},		ToolTipDir = "DOWN",		ToolTipText = GARBAGEMAN_TUTORIAL3 } 
		GarbageMan.HelpPlate[3] = { ButtonPos = { x = 228,	y = 0 }, HighLightBox = { x = 154, y = -10, width = 96, height = 30},		ToolTipDir = "DOWN",		ToolTipText = GARBAGEMAN_TUTORIAL4 } 
		
		HelpPlateTooltip.Text:SetText(GARBAGEMAN_HELP_BUTTON_TOOLTIP)
		HelpPlate_Show( GarbageMan.HelpPlate, MerchantFrame, GarbageMan.tutorialButton, true );

	elseif(MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 and  not HelpPlate_IsShowing(GarbageMan.HelpPlate)) then 
		GarbageMan.PositionFilterTooltip()
		GarbageMan.PositionGarbageButtonTooltip()
		
		GarbageMan.HelpPlate[3] = nil

		HelpPlateTooltip.Text:SetText(GARBAGEMAN_HELP_BUTTON_TOOLTIP)
		HelpPlate_Show( GarbageMan.HelpPlate, MerchantFrame, GarbageMan.tutorialButton, true );
	else
		HelpPlate_Hide(true);
	end
end


--Purpose: Sets text for tutorial button tool tip
--Returns: Nothing
function GarbageMan.Main_HelpPlate_Button_ShowTooltip(self)
	if(MerchantFrame:IsShown()) then
		HelpPlateTooltip.Text:SetText(GARBAGEMAN_HELP_BUTTON_TOOLTIP);
		HelpPlateTooltip:Show()
	elseif(BankFrame:IsShown()) then 
		HelpPlateTooltip.Text:SetText(GARBAGEMAN_HELP_BANK_TOOLTIP);
		HelpPlateTooltip:Show()
	end
end