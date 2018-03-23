local SAVED_VARIABLES = {"GarbageMan_BlackList", "GarbageMan_WhiteList", "GarbageMan_Auto_Sell_Garbage", "GarbageMan_Auto_Sell_LowerGear", "GarbageMan_Auto_Delete", 
						"GarbageMan_Expansion_Choice", "GarbageMan_Auto_Refund", "GarbageMan_Auto_Bind", "GarbageMan_Sell_Threshold", "GarbageMan_SetIlvl"}

local TEXTCB_GROUP1 = 
{ 
	{"Enable BlackList", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells items on the BlackList as Garbage\n\n|cFFFF0000Disabled:|r Sells only Garbage items"},
	{"Enable WhiteList", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Does not sell items on the WhiteList\n\n|cFFFF0000Disabled:|r Sells all Garbage items"}
}

local TEXTCB_GROUP2 = 
{
	{"Auto Sell Garbage", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells Garbage to immediately on interaction with Merchant NPC\n\n|cFFFF0000Disabled:|r Sells Garbage when Garbage Button on Merchant window is Pressed"},
	{"Sell Lower i-lvl Soulbound Gear", "|cFF42d9f4Character-specific|r\n|cFF00FF00Enabled|r: Sells gear if lower item level than associated equipped slot\n\n|cFFFF0000Disabled:|r Only sells Garbage items"},
	{"Delete No-Sell-Price BlackList Items", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Deletes items in the BlackList that cannot be sold. BlackList must be enabled\n\n|cFFFF0000Disabled:|r Does not delete any items"}
}

local TEXTCB_GROUP3 = 
{
	{"Auto Accept Refund", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells item that can still be refunded for full gold\n\n|cFFFF0000Disabled:|r Does not sell items that prompt dialog box to refund item for gold"},
	{"Auto Accept Sell Tradeable", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells item that is still tradeable with party/raid group\n\n|cFFFF0000Disabled:|r Does not sell items that prompt dialog box to soulbind tradeable gear"}
	--,{"Auto Accept Remove From Wardrobe", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells item that will be removed from wardrobe\n\n|cFFFF0000Disabled:|r Does not sell items that prompt dialog box to remove item from wardrobe"}
}

local TEXTCB_GROUP4 = 
{
	{"", "|cFF42d9f4Character-specific|r\n|cFF00FF00Enabled|r: Sells item below set item level\n\n|cFFFF0000Disabled:|r Does not sell items below the set item level"}
	--,{"Auto Accept Remove From Wardrobe", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells item that will be removed from wardrobe\n\n|cFFFF0000Disabled:|r Does not sell items that prompt dialog box to remove item from wardrobe"}
}

local EXPANSIONS_OPTIONS = {
		"None",
		"Burning Crusade",
		"Wrath of the Lich King",
		"Cataclysm",
		"Mists of Pandaria",
		"Warlords of Draenor",
		"Legion"
} 

local expansion_lookuptable = {
	  	["None"] = 1,-- 60
		["Burning Crusade"] = 2,-- 70
		["Wrath of the Lich King"] = 3,--,
		["Cataclysm"] = 4,--,
		["Mists of Pandaria"] = 5,--,
		["Warlords of Draenor"] = 6,--,
		["Legion"] = 7--
  }

--Purpose: Sorts keys of BlackList/WhiteList items based on item name
--Arguments: [table] BlackList or WhiteList key, value (itemid, itemName) pairs
--Returns: [array] sorted array of keys using the key's value
function GarbageMan.SortAssociativeArray(list)
	local keys = {}
	local newList = {}
	 for key in pairs(list) do
	    table.insert(keys, key)
	 end
	 table.sort(keys, function(a, b) return list[a] < list[b] end)
  return keys
end

--Purpose: Initializes Expansion dropdown menu-- Feature not ready yet!
--Arguments: [GarbageMan Object] self; [integer] level determines which option in dropdown menu is selected
--Returns: Nothing
function GarbageMan.expansionDropDown_initialize(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(EXPANSIONS_OPTIONS) do 
		info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.value = v
		info.func = GarbageMan.expansionDropDown_OnClick
		UIDropDownMenu_AddButton(info, level)
	end
end 

--Purpose: Sets the dropdown menu options when expansiondropdown loads
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.expansionDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, GarbageMan.expansionDropDown_initialize)
end

--Purpose: Sets expansion choice as the dropdown menu choice selected and saves expansion choice --Feature not yet ready!
--Arguments: [int] selects choice in dropdown menu
--Returns: Nothing
function GarbageMan.expansionDropDown_SetSelectedID(saved_variable)
  	local id = expansion_lookuptable[saved_variable] or 1 --default to None if not found in look up table
   	UIDropDownMenu_SetSelectedID(GarbageMan.expansionDropDown, id)
   	GarbageMan_Expansion_Choice = EXPANSIONS_OPTIONS[UIDropDownMenu_GetSelectedID(GarbageMan.expansionDropDown)] 
end 

--Purpose: Sets click to select option on expansiondropdown menu
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.expansionDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(GarbageMan.expansionDropDown, self:GetID())
end


--Purpose: Sets click to to toggle settings for checkboxes and their associated value
--Arguments: [GarbageMan Object] self; [integer] index specifying which variable to toggle
--Returns: Nothing
function GarbageMan.CheckBoxButton_OnClick(self, index)
	_G[SAVED_VARIABLES[index]] = not _G[SAVED_VARIABLES[index]]
end

--Purpose: Creates and initializes checkboxes
--Arguments: [Frame Object] panel, specifies parent of checkboxes; [table] list, specifies text for each checkbox; [integer] group, specifies which checkbox group that is being generated; [integer] x and [integer] y specify the offset from the anchor
--Returns: Nothing
function GarbageMan.generate_CheckBoxButtons(panel, list, group, x, y)
	
	local last_anchor = anchor
	for k,v in pairs(list) do
		local checkbox = CreateFrame("CheckButton", GarbageMan.name.."CheckBoxButton"..group..k, panel,"ChatConfigCheckButtonTemplate")
		_G[checkbox:GetName().."Text"]:SetText(v[1])
		checkbox.tooltip = v[2]
		if(last_anchor) then
			checkbox:SetPoint("TOPLEFT", last_anchor,"BOTTOMLEFT")
		elseif(group == 4) then 
			checkbox:SetPoint("LEFT", _G[GarbageMan.name.."OR"],"RIGHT", 15, 0)
		else 
			checkbox:SetPoint("TOPLEFT", x, y)
		end
		if(group == 2) then
			checkbox:SetScript("OnClick", function(self) GarbageMan.CheckBoxButton_OnClick(self, k + 2) end)
		elseif(group == 3) then
			checkbox:SetScript("OnClick", function(self) GarbageMan.CheckBoxButton_OnClick(self, k + 6) end)
		elseif(group == 4) then
			checkbox:SetScript("OnClick", function(self) GarbageMan.CheckBoxButton_OnClick(self, k + 8) end)
		else
			checkbox:SetScript("OnClick", function(self) GarbageMan.CheckBoxButton_OnClick(self, k) end)
		end
		last_anchor = checkbox
	end
end

--Purpose: Creates and formats text display
--Arguments: [Frame Object] panel, specifies parent of font strings
--Returns: Nothing
function GarbageMan.generate_Text(panel)
	local title = panel:CreateFontString(nil, "BORDER", "SplashHeaderFont")
	title:SetPoint("TOPLEFT", 12, -12)
	title:SetText(panel.name)

	local description =  panel:CreateFontString(nil, "BORDER", "GameFontNormalSmall")
	description:SetPoint("TOP", title, "BOTTOM", 110, -2)
	description:SetTextColor(1,1,1)
	description:SetText(GarbageMan.description)

	--local TITLES = {"What's Garbage Settings", "Automation Settings", " Up to this Expansion is Garbage", "Dialog Pop-up Settings"} --expansion settings --Feature not yet ready!
	local TITLES = {"What's Garbage Settings", "Automation Settings", "Dialog Pop-up Settings"}
	local x = 110
	local y = -10
	for k,v in pairs(TITLES) do 
		local title = panel:CreateFontString(GarbageMan.name.."Title"..k, "BORDER", "Fancy22Font")
		title:SetPoint("TOP", description, "BOTTOM", x,y)
		title:SetText(TITLES[k])
		y = y-90
	end
	local title = panel:CreateFontString(GarbageMan.name.."OR", "BORDER", "Fancy14Font")

	title:SetPoint("TOP", description, "BOTTOM", 120, -140)
	title:SetText("")

	title = panel:CreateFontString(GarbageMan.name.."OR".."text", "BORDER", "GameFontNormal")
	title:SetTextColor(1,1,1)

	--text by textfield 
	title:SetPoint("LEFT", _G[GarbageMan.name.."OR"], "RIGHT", 40, 0)
	title:SetText("Sell Gear Below this Item Level")
end

--Purpose: Creates and initializes dropdown menus
--Arguments: [Frame Object] panel, specifies parent of dropdownmenu
--Returns: Nothing
function GarbageMan.generate_DropDownMenus(panel)
	GarbageMan.expansionDropDown = CreateFrame("frame", GarbageMan.name..".ExpansionDropDownMenu", panel, "UIDropDownMenuTemplate")
	GarbageMan.expansionDropDown:SetPoint("CENTER", 0, -20)
	UIDropDownMenu_Initialize(GarbageMan.expansionDropDown, GarbageMan.expansionDropDown_initialize)
	UIDropDownMenu_SetWidth(GarbageMan.expansionDropDown, 150)
	UIDropDownMenu_SetButtonWidth(GarbageMan.expansionDropDown, 174)

	GarbageMan.expansionDropDown_SetSelectedID(GarbageMan_Expansion_Choice)

	UIDropDownMenu_JustifyText(GarbageMan.expansionDropDown, "LEFT")
	
	GarbageMan.expansionDropDown:SetScript("OnEnter",  function(self) GameTooltip:SetOwner(GarbageMan.expansionDropDown, "ANCHOR_RIGHT")
		GameTooltip:SetText("|cFF42d9f4Character-specific|r\n|cFF00FF00Expansion:|r Sells crafting items before selected expansion \n\n|cFFFF0000None:|r Only sells Garbage items") GameTooltip:Show() end)
	GarbageMan.expansionDropDown:SetScript("OnLeave",  function(self) GameTooltip:Hide() end)
end

--Purpose: Extracts number from textbox
--Returns: Nothing
function GarbageMan.EditBox_OnUpdate()
	local ilvl =tonumber(_G[GarbageMan.name.."EditBox"]:GetText())
	if(type(ilvl) == "number") then
		GarbageMan_SetIlvl = ilvl
	else
		GarbageMan_SetIlvl = 0
	end
end

--Purpose: Creates and initializes edit boxes
--Returns: Nothing
function GarbageMan.generate_EditBoxs(panel, anchor)
	local garbage_editbox = CreateFrame("EditBox", GarbageMan.name.."EditBox", panel, "GarbageManEditBoxTemplate")
	garbage_editbox:SetScript("OnTextChanged", GarbageMan.EditBox_OnUpdate)
	garbage_editbox:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
end

--Purpose: Saves user settings
--Returns: Nothing
function GarbageMan.GarbageMan_SaveSession()
	local group; local i
	for k,v in pairs(SAVED_VARIABLES) do

		if(k <= 2) then
			group = 1
			i=k
		elseif(k == 9) then --This SAVED_VARIABLE is not accessed by a checkbox
			group = 4
			i = k-8
		elseif(k == 10) then
			break
		elseif(k <= 5) then
			group = 2
			i = k-2
		else
			group = 3
			i = k - 6
		end
		if(k ~=6) then
			if(_G[GarbageMan.name.."CheckBoxButton"..group..i]:GetChecked() == true) then
				_G[v] = true
			else
				_G[v] = false
			end
		end
	end
	local id= UIDropDownMenu_GetSelectedID(GarbageMan.expansionDropDown)
	_G[GarbageMan_Expansion_Choice] = EXPANSIONS_OPTIONS[UIDropDownMenu_GetSelectedID(GarbageMan.expansionDropDown)] 
end

--Purpose: Returns settings to default
--Returns: Nothing
function GarbageMan.GarbageMan_Default()
	local group; local i
	for k,v in pairs(SAVED_VARIABLES) do

		if(k <= 2) then
			group = 1
			i=k
		elseif(k == 9) then --This SAVED_VARIABLE is not accessed by a checkbox
			group = 4
			i = k-8
		elseif(k == 10) then
			break
		elseif(k <= 5) then
			group = 2
			i = k-2
		else
			group = 3
			i = k - 6
		end
		if(k ~=6) then
			if(_G[v] == nil) then 
				_G[v] = false
			elseif(_G[v] == true) then
				_G[GarbageMan.name.."CheckBoxButton"..group..i]:SetChecked(false)
				_G[v] = false

			end
		end
	end
	GarbageMan_SetIlvl = 0
	_G[GarbageMan.name.."EditBox"]:SetText(tostring(0))
	_G[GarbageMan.name.."EditBox"]:SetCursorPosition(0)
	--GarbageMan_Expansion_Choice = UIDropDownMenu_GetSelectedName(GarbageMan.expansionDropDown) Feature not yet ready

end

--Purpose: Creates UI elements for interface options panel
--Returns: Nothing
function GarbageMan.generate_InterfacePanel()
	local panel =  CreateFrame("Frame", "GarbageManPanel", UIParent)
	panel.name = GarbageMan.name
	--panel.okay = GarbageMan_SaveSession decided to save on edits instead
	panel.default = GarbageMan.GarbageMan_Default

	GarbageMan.generate_Text(panel)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP1, 1, 40, -80)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP2, 2, 40, -170)
	--GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP3, 3, 40, -360) --Feature Not ready yet! No need to make room for it
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP3, 3, 40, -270)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP4, 4, 40, -170)

	--GarbageMan.generate_DropDownMenus(panel)
	GarbageMan.generate_EditBoxs(panel, _G[GarbageMan.name.."OR".."text"])
	GarbageMan.generate_Tutorial()
	InterfaceOptions_AddCategory(panel)

end

--Purpose: initializes GarbageMan add-on
--Returns: Nothing
function GarbageMan.GarbageMan_AddonLoaded()
	local i 
	local group

	GarbageMan.generateUI()
	GarbageMan.generate_InterfacePanel()
	for k,v in pairs(SAVED_VARIABLES) do

		if(k <= 2) then
			group = 1
			i=k
		elseif(k == 9) then --This SAVED_VARIABLE is not accessed by a checkbox
			group = 4
			i = k-8
		elseif(k == 10) then
			break
		elseif(k <= 5) then
			group = 2
			i = k-2
		else
			group = 3
			i = k - 6
		end
		if(k ~=6) then
			if(_G[v] == nil) then 
				_G[v] = false
			elseif(_G[v] == true) then

				_G[GarbageMan.name.."CheckBoxButton"..group..i]:SetChecked(true)

			end
		end
	end

	_G[GarbageMan.name.."EditBox"]:SetText(tostring(GarbageMan_SetIlvl))
	_G[GarbageMan.name.."EditBox"]:SetCursorPosition(0)

	hooksecurefunc("MerchantItemButton_OnClick", GarbageMan.MerchantItemButton_OnClick)
	hooksecurefunc("ContainerFrameItemButton_OnClick", GarbageMan.ContainerFrameItemButton_OnClick)
	hooksecurefunc("MerchantFrame_Update", function(self) GarbageMan.GarbageTabButton_Update(false) end)
	hooksecurefunc("MerchantItemButton_OnEnter", GarbageMan.MerchantItemButton_OnEnter)
	hooksecurefunc("BankFrameItemButton_Update", GarbageMan.BankFrameItemButton_Update)
	hooksecurefunc("Main_HelpPlate_Button_ShowTooltip",  GarbageMan.Main_HelpPlate_Button_ShowTooltip)

	_G["BankFrame"]:HookScript("OnUpdate", function(self) GarbageMan.FindGarbage(false) end)

	GarbageMan_ItemWhiteList = GarbageMan_ItemWhiteList or {}
	GarbageMan_ItemBlackList = GarbageMan_ItemBlackList or {}
	GarbageMan_ItemWhiteListPC = GarbageMan_ItemWhiteListPC or {}
	GarbageMan_ItemBlackListPC = GarbageMan_ItemBlackListPC or {}
	
	GarbageMan_SetIlvl = GarbageMan_SetIlvl or 0
	GarbageMan.sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
	GarbageMan.sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
end
