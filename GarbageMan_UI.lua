local SAVED_VARIABLES = {"GarbageMan_BlackList", "GarbageMan_WhiteList", "GarbageMan_Auto_Sell_Garbage", "GarbageMan_Auto_Sell_LowerGear", "GarbageMan_Auto_Delete", 
						"GarbageMan_Expansion_Choice", "GarbageMan_Auto_Refund", "GarbageMan_Auto_Bind", "GarbageMan_Sell_Threshold", "GarbageMan_SetIlvl"}

local TEXTCB_GROUP1 = 
{ 
	{"Enable BlackList", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells items on the BlackList as Garbage\n\n|cFFFF0000Disabled:|r Sells only Garbage items"},
	{"Enable WhiteList", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Does not sell Garbage items on the WhiteList\n\n|cFFFF0000Disabled:|r Sells all Garbage items"}
}

local TEXTCB_GROUP2 = 
{
	{"Auto Sell Garbage", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Sells Garbage to immediately on interaction with Merchant NPC\n\n|cFFFF0000Disabled:|r Sells Garbage when Garbage Button on Merchant window is Pressed"},
	{"Sell Lower i-lvl Soulbound Gear", "|cFF42d9f4Character-specific|r\n|cFF00FF00Enabled|r: Sells gear if lower item level than associated equipped slot\n\n|cFFFF0000Disabled:|r Only sells Garbage items"},
	{"Delete No-Sell-Price BlackList Items", "|cFF42d9f4Account-wide|r\n|cFF00FF00Enabled|r: Deletes items in the BlackList that cannot be sold\n\n|cFFFF0000Disabled:|r Does not delete any items"}
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

local LIST_OPTIONS = {
	"Account-Wide",
	"Character-specific"
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

GarbageMan = {
	name = "GarbageMan",
	description = "--version 7.03.05 by ScienficInquiry, |cFF42d9f4Scienfic.Inquiry@gmail.com|r\n Sells Garbage items [grey quality items]",
	BuyBackList = {},
	BankGarbageBags = {},
	WLselectedPage = 1,
	BLselectedPage = 1,
	max_pages = 0,
	toggleFilter = false,
	toggleFilterBank =  true,
	isBankOpen = false
}
local garbageTab_button
local expansionDropDown
local listsDropDown
local garbage_buttonTooltip
local sortedKeysWL
local sortedKeysBL

local numinlist = 0
local removeinlist = 1

function GarbageMan.SortAssociativeArray(list)
	local keys = {}
	local newList = {}
	 for key in pairs(list) do
	    table.insert(keys, key)
	 end
	 table.sort(keys, function(a, b) return list[a] < list[b] end)
  return keys
end

function GarbageMan.expansionDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, GarbageMan.expansionDropDown_initialize)
end

function GarbageMan.expansionDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(expansionDropDown, self:GetID())
end

function GarbageMan.ListsDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(listsDropDown, self:GetID())
end

function GarbageMan.CheckBoxButton_OnClick(self, index)
	_G[SAVED_VARIABLES[index]] = not _G[SAVED_VARIABLES[index]]

end

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

function GarbageMan.generate_Text(panel)
	local title = panel:CreateFontString(nil, "BORDER", "SplashHeaderFont")
	title:SetPoint("TOPLEFT", 12, -12)
	title:SetText(panel.name)

	local description =  panel:CreateFontString(nil, "BORDER", "GameFontNormalSmall")
	description:SetPoint("TOP", title, "BOTTOM", 110, -2)
	description:SetTextColor(1,1,1)
	description:SetText(GarbageMan.description)

	--local TITLES = {"What's Garbage Settings", "Automation Settings", " Up to this Expansion is Garbage", "Dialog Pop-up Settings"}
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
	title:SetText("OR")

	title = panel:CreateFontString(GarbageMan.name.."OR".."text", "BORDER", "GameFontNormal")
	title:SetTextColor(1,1,1)

	title:SetPoint("LEFT", _G[GarbageMan.name.."OR"], "RIGHT", 40, 0)
	title:SetText("Sell Gear Below this Item Level")

end

function GarbageMan.expansionDropDown_SetSelectedID(saved_variable)
  	

  	local id = expansion_lookuptable[saved_variable] or 1 --default to None if not found in look up table

   	UIDropDownMenu_SetSelectedID(expansionDropDown, id)
   	GarbageMan_Expansion_Choice = EXPANSIONS_OPTIONS[UIDropDownMenu_GetSelectedID(expansionDropDown)] 
end 
function GarbageMan.ListsDropDown_SetSelectedID(choice)
  	

  	local id = choice or 1 --default to None if not found in look up table

   	UIDropDownMenu_SetSelectedID(listsDropDown, id)
   	
end 

function GarbageMan.generate_DropDownMenus(panel)
	--expansionDropDown = CreateFrame("frame","GarbageMan.ExpansionDropDownMenu", panel, "UIDropDownMenuTemplate")
	--expansionDropDown:SetPoint("CENTER", 0, -20)
	--UIDropDownMenu_Initialize(expansionDropDown, GarbageMan.expansionDropDown_initialize)
	--UIDropDownMenu_SetWidth(expansionDropDown, 150)
	--UIDropDownMenu_SetButtonWidth(expansionDropDown, 174)

	--GarbageMan.expansionDropDown_SetSelectedID(GarbageMan_Expansion_Choice)

	--UIDropDownMenu_JustifyText(expansionDropDown, "LEFT")
	
	--expansionDropDown:SetScript("OnEnter",  function(self) GameTooltip:SetOwner(expansionDropDown, "ANCHOR_RIGHT")
	--	GameTooltip:SetText("|cFF42d9f4Character-specific|r\n|cFF00FF00Expansion:|r Sells crafting items before selected expansion \n\n|cFFFF0000None:|r Only sells Garbage items") GameTooltip:Show() end)
	--expansionDropDown:SetScript("OnLeave",  function(self) GameTooltip:Hide() end)


end

function GarbageMan.EditBox_OnUpdate()
	local ilvl =tonumber(_G[GarbageMan.name.."EditBox"]:GetText())

	if(type(ilvl) == "number") then
		GarbageMan_SetIlvl = ilvl

	else

		GarbageMan_SetIlvl = 0
	end
end

function GarbageMan.generate_EditBoxs(panel, anchor)
	local garbage_editbox = CreateFrame("EditBox", GarbageMan.name.."EditBox", panel, "GarbageManEditBoxTemplate")
	garbage_editbox:SetScript("OnTextChanged", GarbageMan.EditBox_OnUpdate)
	garbage_editbox:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
end

function GarbageMan.GarbageMan_SaveSession()
	local group
	local i

	for k,v in pairs(SAVED_VARIABLES) do

		if(k <= 2) then
			group = 1
			i=k
		elseif(k>=6 and k<=9) then --This SAVED_VARIABLE is not accessed by a checkbox

		elseif(k == 10) then
			group = 4
		else
			group = 2
			i = k-2
		end
		if(_G[GarbageMan.name.."CheckBoxButton"..group..i]:GetChecked() == true) then
			_G[v] = true
		else
			_G[v] = false
		end
	end

	local id= UIDropDownMenu_GetSelectedID(expansionDropDown)

	_G[GarbageMan_Expansion_Choice] = EXPANSIONS_OPTIONS[UIDropDownMenu_GetSelectedID(expansionDropDown)] 

end

function GarbageMan.GarbageMan_Default()
	local group
	local i

	for k,v in pairs(SAVED_VARIABLES) do
		if(k <= 2) then
			group = 1
			i=k
		elseif(k == 6) then --This SAVED_VARIABLE is not accessed by a checkbox
			break
		else
			group = 2
			i = k-2
		end
		_G[GarbageMan.name.."CheckBoxButton"..group..i]:SetChecked(false)
		_G[v] = false
	end

	GarbageMan_Expansion_Choice = UIDropDownMenu_GetSelectedName(expansionDropDown) 

end

function GarbageMan.generate_InterfacePanel()
	local panel =  CreateFrame("Frame", "GarbageManPanel", UIParent)
	panel.name = "GarbageMan"
	--panel.okay = GarbageMan_SaveSession
	panel.default = GarbageMan.GarbageMan_Default

	GarbageMan.generate_Text(panel)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP1, 1, 40, -80)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP2, 2, 40, -170)
	--GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP3, 3, 40, -360)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP3, 3, 40, -270)
	GarbageMan.generate_CheckBoxButtons(panel, TEXTCB_GROUP4, 4, 40, -170)

	--GarbageMan.generate_DropDownMenus(panel)
	GarbageMan.generate_EditBoxs(panel, _G[GarbageMan.name.."OR".."text"])

	InterfaceOptions_AddCategory(panel)

end

function GarbageMan.GetListLength(list)
local length = 0
	for k,v in pairs(list) do
		length = length + 1
	end
	return length
end

function GarbageMan.generate_ListDropDownMenus()
	listsDropDown = CreateFrame("frame","GarbageMan.ListsDropDownMenu", MerchantFrame, "GarbageManListFilterTemplate")
	UIDropDownMenu_SetWidth(listsDropDown , 115);
	UIDropDownMenu_Initialize(listsDropDown, GarbageMan.ListsDropDown_initialize);
	GarbageMan.ListsDropDown_SetSelectedID(1)

	listsDropDown:SetScript("OnEnter",  function(self) GameTooltip:SetOwner(listsDropDown, "ANCHOR_RIGHT")
		GameTooltip:SetText("|cFF42d9f4Character-specific|r\n|cFF00FF00Account-Wide:|r Edit Account-Wide WhiteList/BlackList \n\n|cFFFF0000Character-specific:|r Edit Character-specific WhiteList/BlackList ") GameTooltip:Show() end)
	listsDropDown:SetScript("OnLeave",  function(self) GameTooltip:Hide() end)
	listsDropDown:Show()
end
function GarbageMan.UpdateMainTab_OnEnter(self)
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ) 
	GameTooltip:SetText("WhiteList and BlackList Items") 
	if(MerchantFrame.selectedTab ~= 3) then
		local oldtab = MerchantFrame.selectedTab; local oldgarbagetab = _G[GarbageMan.name.."ContainerFrame"].selectedTab; 
		MerchantFrame.selectedTab = 3; 
		GarbageMan.GarbageTabButton_Update()
		_G[GarbageMan.name.."ContainerFrame"].selectedTab = 2; 
		GarbageMan.GarbageTabButton_Update(); 
		_G[GarbageMan.name.."ContainerFrame"].selectedTab = oldgarbagetab
		MerchantFrame.selectedTab = oldtab 
		MerchantFrame_Update()
	end 
end

function GarbageMan.UpdateSubTabNext_OnEnter()
	local num_itemsWL = GarbageMan.GetListLength(GarbageMan_ItemWhiteList)
	local oldpageWL = GarbageMan.WLselectedPage; local oldpageBL = GarbageMan.BLselectedPage
	if(oldpageWL ~= math.ceil(num_itemsWL / BUYBACK_ITEMS_PER_PAGE) or num_itemsWL ~= 0) then 
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage + 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.WLselectedPage = oldpageWL
		GarbageMan.GarbageTabButton_Update(true)
	end
	local num_itemsBL = GarbageMan.GetListLength(GarbageMan_ItemBlackList)
	if(oldpageBL ~= math.ceil(num_itemsBL / BUYBACK_ITEMS_PER_PAGE) or num_itemsBL ~= 0) then 
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage + 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.BLselectedPage = oldpageBL
		GarbageMan.GarbageTabButton_Update(true)
	end

end

function GarbageMan.UpdateSubTabPrev_OnEnter()
	local oldpageWL = GarbageMan.WLselectedPage; local oldpageBL = GarbageMan.BLselectedPage
	if(oldpageWL ~= 1) then 
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
		GarbageMan.GarbageTabButton_Update(true)
		--_G[GarbageMan.name.."ContainerFrame"].selectedTab = 2; 
		--GarbageMan.GarbageTabButton_Update(); 
		GarbageMan.WLselectedPage = oldpageWL
		GarbageMan.GarbageTabButton_Update(true)
	end
	if(oldpageBL ~= 1) then 
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
		GarbageMan.GarbageTabButton_Update(true)
		--_G[GarbageMan.name.."ContainerFrame"].selectedTab = 2; 
		--GarbageMan.GarbageTabButton_Update(); 
		GarbageMan.BLselectedPage = oldpageBL
		GarbageMan.GarbageTabButton_Update(true)
	end
end

function GarbageMan.UpdatePage(list, list_page)
	local num_items = GarbageMan.GetListLength(list)
	if( num_items > BUYBACK_ITEMS_PER_PAGE) then 
		if(list_page == 1) then 
			_G[GarbageMan.name.."PrevButton"]:Disable()
		else
			_G[GarbageMan.name.."PrevButton"]:Enable()
		end
		if (list_page == math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) or num_items == 0) then
			_G[GarbageMan.name.."NextButton"]:Disable();
		else
			_G[GarbageMan.name.."NextButton"]:Enable();
		end
			_G[GarbageMan.name.."pagetext"]:SetText("Page "..list_page.." of "..math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE))

		_G[GarbageMan.name.."pagetext"]:Show();
		MerchantPageText:Hide();
		_G[GarbageMan.name.."PrevButton"]:Show();
		_G[GarbageMan.name.."NextButton"]:Show();
	else
		--MerchantPageText:Hide();
		_G[GarbageMan.name.."pagetext"]:Hide()
		_G[GarbageMan.name.."PrevButton"]:Hide();
		_G[GarbageMan.name.."NextButton"]:Hide();

	end
	

end

function GarbageMan.PrevPage()
	
	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
		GarbageMan.UpdatePage(GarbageMan_ItemWhiteList, GarbageMan.WLselectedPage)
	else
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
		GarbageMan.UpdatePage(GarbageMan_ItemBlackList, GarbageMan.BLselectedPage)
	end
end

function GarbageMan.NextPage()
	
	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage + 1 
		GarbageMan.UpdatePage(GarbageMan_ItemWhiteList, GarbageMan.WLselectedPage)
	else
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage + 1 
		GarbageMan.UpdatePage(GarbageMan_ItemBlackList, GarbageMan.BLselectedPage)
	end
end

function GarbageMan.generate_PageButtons()
	local prev_button = CreateFrame("Button", GarbageMan.name.."PrevButton", MerchantFrame, "GarbageManPrevButtonTemplate")
	prev_button:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 42, 0)
	prev_button:SetScript("Onclick", function(self) GarbageMan.PrevPage() GarbageMan.GarbageTabButton_Update(false)end )
	--predictive page loading
	prev_button:SetScript("OnEnter", GarbageMan.UpdateSubTabPrev_OnEnter)
	prev_button:SetScript("OnLeave", GarbageMan.UpdateSubTabPrev_OnEnter)
	prev_button:SetScript("PostClick", GarbageMan.UpdateSubTabPrev_OnEnter)
	prev_button:Hide()

	local next_button = CreateFrame("Button", GarbageMan.name.."NextButton", MerchantFrame, "GarbageManNextButtonTemplate")
	next_button:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMRIGHT", -42, 0)
	next_button:SetScript("Onclick", function(self) GarbageMan.NextPage() GarbageMan.GarbageTabButton_Update(false)end)
	--predictive page loading
	next_button:SetScript("OnEnter", GarbageMan.UpdateSubTabNext_OnEnter)
	next_button:SetScript("OnLeave", GarbageMan.UpdateSubTabNext_OnEnter)
	next_button:SetScript("PostClick", GarbageMan.UpdateSubTabNext_OnEnter)

	
	next_button:Hide()

	local pagetext = _G["MerchantFrameTab"..MerchantFrame.numTabs]:CreateFontString(GarbageMan.name.."pagetext", "BORDER", "GameFontNormal")
	pagetext:SetPoint("CENTER", MerchantFrame, "BOTTOM", 0, 15)

	
end

function GarbageMan.generate_GarbageSellButton()
 	garbage_button = CreateFrame("Button", "GarbageManSellButton", MerchantFrameInset, "GarbageManItemButtonTemplate")
	garbage_buttonTooltip = CreateFrame("GameTooltip", "GarbageManButtonTooltip", MerchantFrame, "GameTooltipTemplate")
	local garbage_clean_button = CreateFrame("Button", "GarbageManBagItemAutoFilterButton", MerchantFrameInset, "GarbageManBagItemAutoFilterButtonTemplate")
	--garbage_clean_button:SetScript("OnClick", GarbageMan.FilterBags)
	garbage_clean_button:SetPoint("CENTER", MerchantFrame, "BOTTOM", -15, 15)
	garbage_clean_button:Show()
end


function GarbageMan.ContainerFrameItemButton_OnClick(self, button)

		if ( MerchantFrame:IsShown() ) then
			if(button == "LeftButton") then 
				if(MerchantFrame.selectedTab == 3 and _G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then

					local itemID = select(10, GetContainerItemInfo(self:GetParent():GetID(), self:GetID()));

					
					if(itemID) then
						if(GarbageMan_ItemBlackList[itemID]) then
							GarbageMan_ItemBlackList[itemID] = nil
						end
						local itemName = GetItemInfo(itemID)	

						GarbageMan_ItemWhiteList[itemID] = itemName	
						sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
						MerchantFrame_Update()

						if(self:GetParent():GetID() ~= 0) then 
							PutItemInBag(self:GetParent():GetID() + 19) --bag argument starts from 20-23, but bag id starts from 0-3
						else
							PutItemInBackpack()
						end
					end
					
				end
				if(MerchantFrame.selectedTab == 3 and _G[GarbageMan.name.."ContainerFrame"].selectedTab == 2) then

					local itemID = select(10, GetContainerItemInfo(self:GetParent():GetID(), self:GetID()));
					if(itemID) then
						if(GarbageMan_ItemWhiteList[itemID]) then
							GarbageMan_ItemWhiteList[itemID] = nil
						end
						local itemName = GetItemInfo(itemID)	

						GarbageMan_ItemBlackList[itemID] = itemName
						sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
						MerchantFrame_Update()
						if(self:GetParent():GetID() ~= 0) then 
							PutItemInBag(self:GetParent():GetID() + 19)
						else
							PutItemInBackpack()
						end
					end
				end
			end

		end
end
function GarbageMan.GetListItemInfo(table, index, sortedKeys)
	if(sortedKeys[index]) then 
		return sortedKeys[index], table[sortedKeys[index]]
	else 
		return nil, nil
	end
end

function GarbageMan.MerchantItemButton_OnClick(self, button)
	
	if(MerchantFrame.selectedTab == 3) then
	--elseif(MerchantFrame.selectedTab == 3) then
		if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then

			local itemID, itemName = GarbageMan.GetListItemInfo(GarbageMan_ItemWhiteList, self:GetID(), sortedKeysWL)
			if(itemName) then 

				GarbageMan_ItemWhiteList[itemID] = nil
				local num_items = GarbageMan.GetListLength(GarbageMan_ItemWhiteList)
				if( GarbageMan.WLselectedPage > math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) and GarbageMan.WLselectedPage ~= 1) then
					GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
				end
				sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
				MerchantFrame_Update()
			end
		end
		if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 2) then


			local itemID, itemName = GarbageMan.GetListItemInfo(GarbageMan_ItemBlackList, self:GetID(), sortedKeysBL)
			if(itemName) then 

				GarbageMan_ItemBlackList[itemID] = nil
				local num_items = GarbageMan.GetListLength(GarbageMan_ItemBlackList)
				if( GarbageMan.BLselectedPage > math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) and GarbageMan.BLselectedPage ~= 1) then
					GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
				end
				sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
				MerchantFrame_Update()
			end
		end

	end
end

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

function GarbageMan.ListsDropDown_initialize(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(LIST_OPTIONS) do 
		info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.value = v
		info.func = GarbageMan.ListsDropDown_OnClick
		UIDropDownMenu_AddButton(info, level)
	end
end 

function GarbageMan.Generate_SubTabButtons()
	local GarbageMan_Container = CreateFrame("Frame", GarbageMan.name.."ContainerFrame", MerchantFrame)
	PanelTemplates_SetNumTabs(GarbageMan_Container, 2)

	

	local tab1 = CreateFrame("Button", GarbageMan.name.."ContainerFrameTab".. 1, GarbageMan_Container,"TabButtonTemplate")
	--tab1:SetPoint("BOTTOMLEFT", MerchantFrameInset, "TOPLEFT", 40, 0)
	tab1:SetPoint("BOTTOMLEFT", MerchantFrameInset, "TOPLEFT", 0, 0)
	tab1:SetText("WhiteList")
	tab1:SetID(1)
	PanelTemplates_TabResize(tab1)

	tab1:SetScript("OnEnter", function(self) GameTooltip:SetOwner( self, "ANCHOR_RIGHT") GameTooltip:SetText("Left-Click Items to add to WhiteList") end)
	tab1:SetScript("OnLeave", GameTooltip_Hide)
	tab1:SetScript("OnClick", function(self) PanelTemplates_SetTab(GarbageMan_Container, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)
	--tab1:SetScript("OnUpdate", GarbageMan.GarbageTabButton_Update)
	tab1:Hide()
	
	local tab2 = CreateFrame("Button", GarbageMan.name.."ContainerFrameTab".. 2, GarbageMan_Container,"TabButtonTemplate")
	tab2:SetPoint("TOPLEFT", tab1, "TOPRIGHT", -5, 0)
	tab2:SetText("BlackList")
	PanelTemplates_TabResize(tab2)
	tab2:SetID(2)
	

	tab2:SetScript("OnEnter",  function(self) GameTooltip:SetOwner( self, "ANCHOR_RIGHT") GameTooltip:SetText("Left-Click Items to add to BlackList") end)

	tab2:SetScript("OnLeave", GameTooltip_Hide)
	tab2:SetScript("OnClick", function(self) PanelTemplates_SetTab(GarbageMan_Container, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)

	tab2:Hide()
	PanelTemplates_SetTab(GarbageMan_Container, 1)

end 

function GarbageMan.MerchantItemButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
	if ( MerchantFrame.selectedTab == 1 ) then
		GameTooltip:SetMerchantItem(button:GetID());
		GameTooltip_ShowCompareItem(GameTooltip);
		MerchantFrame.itemHover = button:GetID();
	elseif(MerchantFrame.selectedTab == 2) then
		GameTooltip:SetBuybackItem(button:GetID());
		if ( IsModifiedClick("DRESSUP") and button.hasItem ) then
			ShowInspectCursor();
		else
			ShowBuybackSellCursor(button:GetID());
		end
	
	else
		GameTooltip:SetHyperlink(button.link)
		ShowInspectCursor();
	end
	
end

function GarbageMan.ClearPage()
	-- Hide all merchant related items
	MerchantRepairAllButton:Hide();
	MerchantRepairItemButton:Hide();
	MerchantBuyBackItem:Hide();
	MerchantPrevPageButton:Hide();
	MerchantNextPageButton:Hide();
	MerchantFrameBottomLeftBorder:Hide();
	MerchantFrameBottomRightBorder:Hide();
	MerchantRepairText:Hide();
	MerchantPageText:Hide();
	MerchantExtraCurrencyBg:Hide()
	MerchantExtraCurrencyInset:Hide()
	MerchantMoneyFrame:Hide()
	MerchantMoneyBg:Hide()
	MerchantMoneyInset:Hide()
	MerchantGuildBankRepairButton:Hide();
	MerchantFrameLootFilter:Hide()

	-- Hide BuyBack Background
	BuybackBG:Hide();
end
function GarbageMan.UpdateCurrency(onGarbageTab)
	local currencies = { GetMerchantCurrencies() }
	local numCurrencies = #currencies;
	for index = 1, numCurrencies do
			local tokenButton = _G["MerchantToken"..index];
			if(onGarbageTab) then 
				 _G["MerchantToken"..1]:Hide()
			else
				if(_G["MerchantToken"..1]) then 
					_G["MerchantToken"..1]:Show()
					
				end
			end

	end
end
function GarbageMan.GarbageTabButton_Update(preview)

	if(MerchantFrame.selectedTab == 1 or MerchantFrame.selectedTab == 2) then
		local currencies = { GetMerchantCurrencies() }
		local numCurrencies = #currencies;
		MerchantMoneyFrame:Show()
		MerchantMoneyBg:Show()
		MerchantMoneyInset:Show()
		MerchantFrameLootFilter:Show()
		MerchantFramePortrait:Show()
		MerchantFramePortraitFrame:Show()
		_G["GarbageMan.ListsDropDownMenu"]:Hide()
		if(numCurrencies >= 1) then 
			MerchantExtraCurrencyBg:Show()
			MerchantExtraCurrencyInset:Show()
			_G["GarbageManBagItemAutoFilterButton"]:ClearAllPoints()
			_G["GarbageManBagItemAutoFilterButton"]:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 140, -30)
		else
			_G["GarbageManBagItemAutoFilterButton"]:ClearAllPoints()
			_G["GarbageManBagItemAutoFilterButton"]:SetPoint("CENTER", MerchantFrame, "BOTTOM", -20, 14)
		end

		--_G["MerchantToken1"]:Show()
		GarbageMan.UpdateCurrency(false)
		_G[GarbageMan.name.."pagetext"]:Hide();
		_G[GarbageMan.name.."PrevButton"]:Hide();
		_G[GarbageMan.name.."NextButton"]:Hide();
		_G[GarbageMan.name.."ContainerFrameTab".. 1]:Hide()
		_G[GarbageMan.name.."ContainerFrameTab".. 2]:Hide()
		
		return
	end




	GarbageMan.ClearPage()
	MerchantNameText:SetText("GarbageMan") 
	--MerchantFramePortrait:SetTexture("Interface/Garrison/Portraits/EnemyPortrait_2096")
	MerchantFramePortrait:Hide()
	MerchantFramePortraitFrame:Hide()
	MerchantItem11:Show();
	MerchantItem12:Show();
	

	--_G["MerchantToken1"]:Hide()
	GarbageMan.UpdateCurrency(true)
	_G["GarbageManBagItemAutoFilterButton"]:ClearAllPoints()
	_G["GarbageManBagItemAutoFilterButton"]:SetPoint("CENTER", MerchantFrame, "BOTTOM", -50, 14)
	_G["GarbageMan.ListsDropDownMenu"]:Show()

	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -15);
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -15);
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -15);
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -15);
	_G[GarbageMan.name.."ContainerFrameTab".. 1]:Show()
	_G[GarbageMan.name.."ContainerFrameTab".. 2]:Show()

	local t
	local WLpage
	local sortedKeys

	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		t = GarbageMan_ItemWhiteList
		sortedKeys = sortedKeysWL
		WLpage = true
	else

		t = GarbageMan_ItemBlackList
		sortedKeys = sortedKeysBL
		WLpage = false
	end

	--sortedKeys = GarbageMan.SortAssociativeArray(t)

	if(WLpage and not preview) then 
		GarbageMan.UpdatePage(t, GarbageMan.WLselectedPage)
	elseif(not preview) then
		GarbageMan.UpdatePage(t, GarbageMan.BLselectedPage)
	end
	

	local i = 1

	for i=1, BUYBACK_ITEMS_PER_PAGE do

		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		local item = _G["MerchantItem"..i];
		_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide();
		SetItemButtonNameFrameVertexColor(item, 0.5, 0.5, 0.5);
		SetItemButtonSlotVertexColor(item, 1.0, 1.0, 1.0);
		SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
		SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
		_G["MerchantItem"..i.."Name"]:SetText("");
		_G["MerchantItem"..i.."MoneyFrame"]:Hide();
		itemButton:Hide();

		local index
		if(WLpage) then 
			index = (((GarbageMan.WLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i);
		else
			index = (((GarbageMan.BLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i);
		end

		local itemID, name = GarbageMan.GetListItemInfo(t, index, sortedKeys)
		if(itemID) then
			
			_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide();

			local texture = select(10, GetItemInfo(itemID))
			local itemLink = select(2, GetItemInfo(itemID))
			itemButton.link = itemLink
				--print("itemlink = ", itemLink)
			_G["MerchantItem"..i.."Name"]:SetText(name);

			SetItemButtonTexture(itemButton, texture);
			itemButton.UpdateTooltip = GarbageMan.MerchantItemButton_OnEnter
			MerchantFrameItem_UpdateQuality(item, itemLink);
			itemButton:SetID(index);
			itemButton:Show();

			SetItemButtonCount(itemButton, 1);
		end

	end

end

function GarbageMan.generate_GarbageTabButton()
	garbageTab_button = CreateFrame("Button", "MerchantFrameTab"..MerchantFrame.numTabs+1, MerchantFrame, "CharacterFrameTabButtonTemplate", MerchantFrame.numTabs +1)
	garbageTab_button:SetPoint("LEFT", MerchantFrameTab2, "RIGHT", -16, 0)
	garbageTab_button:SetText("GarbageMan")

	--load one more time before display
	garbageTab_button:SetScript("OnEnter", function(self) GarbageMan.UpdateMainTab_OnEnter(self) end)
	garbageTab_button:SetScript("OnLeave", GameTooltip_Hide)
	garbageTab_button:SetScript("OnClick", function(self) PanelTemplates_SetTab(MerchantFrame, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)

	
	garbageTab_button:SetID(MerchantFrame.numTabs+1)
	
	PanelTemplates_TabResize(garbageTab_button)
	PanelTemplates_SetNumTabs(MerchantFrame, MerchantFrame.numTabs + 1)
	
end

function GarbageMan:generateUI()

	local garbageManMerchantFrame = CreateFrame("Frame", "GarbageManMerchantFrame", MerchantFrame, nil, 5)
	garbageManMerchantFrame:SetID(MerchantFrame.numTabs+1)
	GarbageMan.generate_GarbageSellButton()
	GarbageMan.generate_GarbageTabButton()
	GarbageMan.Generate_SubTabButtons()
	GarbageMan.generate_PageButtons()
	GarbageMan.generate_ListDropDownMenus()
end

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
	--hooksecurefunc("BankFrameItemButton_Update", GarbageMan.BankFrameItemButton_Update)
	--_G["MerchantFrameTab"..MerchantFrame.numTabs]:SetScript("OnUpdate", findJunk(false))

	_G["BankFrame"]:HookScript("OnUpdate", function(self) GarbageMan.findJunk(false) end)
	GarbageMan_ItemWhiteList = GarbageMan_ItemWhiteList or {}
	GarbageMan_ItemBlackList = GarbageMan_ItemBlackList or {}
	GarbageMan_ItemWhiteListPC = GarbageMan_ItemWhiteListPC or {}
	GarbageMan_ItemBlackListPC = GarbageMan_ItemBlackListPC or {}
	
	GarbageMan_SetIlvl = GarbageMan_SetIlvl or 0
	sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
	sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
	
end
