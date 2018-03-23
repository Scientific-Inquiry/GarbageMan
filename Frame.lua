local LIST_OPTIONS = {
	"Account-Wide",
	"Character-specific"
}

--Purpose: Retrieve a Dictionary's length
--Arguments: [table] list of key, value pairs
--Returns: [integer] Dictionary length
function GarbageMan.GetListLength(list)
local length = 0
	for k,v in pairs(list) do
		length = length + 1
	end
	return length
end

--Purpose: Selects option in dropdownlist on mouse-click
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.ListsDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(GarbageMan.listsDropDown, self:GetID())
end

--Purpose: Selects option in dropdownlist
--Arguments: [integer] choice (1-7) that picks dropdownmenu option
--Returns: Nothing
function GarbageMan.ListsDropDown_SetSelectedID(choice)  	
  	local id = choice or 1 --default to None if not found in look up table
   	UIDropDownMenu_SetSelectedID(GarbageMan.listsDropDown, id)
end 

--Purpose: creates and initializes dropdownlist 
--Returns: Nothing
function GarbageMan.generate_ListDropDownMenus()
	GarbageMan.listsDropDown = CreateFrame("frame","GarbageMan.ListsDropDownMenu", MerchantFrame, "GarbageManListFilterTemplate")
	UIDropDownMenu_SetWidth(listsDropDown , 115)
	UIDropDownMenu_Initialize(listsDropDown, GarbageMan.ListsDropDown_initialize)
	GarbageMan.ListsDropDown_SetSelectedID(1)

	GarbageMan.listsDropDown:SetScript("OnEnter",  function(self) GameTooltip:SetOwner(listsDropDown, "ANCHOR_RIGHT")
		GameTooltip:SetText("|cFF42d9f4Character-specific|r\n|cFF00FF00Account-Wide:|r Edit Account-Wide WhiteList/BlackList \n\n|cFFFF0000Character-specific:|r Edit Character-specific WhiteList/BlackList ") GameTooltip:Show() end)
	GarbageMan.listsDropDown:SetScript("OnLeave",  function(self) GameTooltip:Hide() end)
	GarbageMan.listsDropDown:Show()
end

--Purpose: Updates/Preloads GarbageManTab on entering the GarbageMan frame
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.UpdateMainTab_OnEnter(self)
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ) 
	GameTooltip:SetText("WhiteList and BlackList Items") 

	--preloading items before using interface
	if(MerchantFrame.selectedTab ~= 3) then
		local oldtab = MerchantFrame.selectedTab; local oldgarbagetab = _G[GarbageMan.name.."ContainerFrame"].selectedTab 
		MerchantFrame.selectedTab = 3 
		GarbageMan.GarbageTabButton_Update()

		_G[GarbageMan.name.."ContainerFrame"].selectedTab = 2 
		GarbageMan.GarbageTabButton_Update() 

		_G[GarbageMan.name.."ContainerFrame"].selectedTab = oldgarbagetab
		MerchantFrame.selectedTab = oldtab 
		MerchantFrame_Update()
	end 
end

--Purpose: Updates/Preloads GarbageManSubTabs on entering the GarbageMan next page button
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.UpdateSubTabNext_OnEnter()
	local num_itemsWL = GarbageMan.GetListLength(GarbageMan_ItemWhiteList)
	local oldpageWL = GarbageMan.WLselectedPage; local oldpageBL = GarbageMan.BLselectedPage
	if(oldpageWL ~= math.ceil(num_itemsWL / BUYBACK_ITEMS_PER_PAGE) or num_itemsWL ~= 0) then 
		--preloading WhiteList items on next page
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage + 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.WLselectedPage = oldpageWL
		GarbageMan.GarbageTabButton_Update(true)
	end
	local num_itemsBL = GarbageMan.GetListLength(GarbageMan_ItemBlackList)
	if(oldpageBL ~= math.ceil(num_itemsBL / BUYBACK_ITEMS_PER_PAGE) or num_itemsBL ~= 0) then 
		--preloading BlackList items on next page
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage + 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.BLselectedPage = oldpageBL
		GarbageMan.GarbageTabButton_Update(true)
	end

end

--Purpose: Updates/Preloads GarbageManSubTabs on entering the GarbageMan prev page button
--Arguments: [GarbageMan Object] self
--Returns: Nothing
function GarbageMan.UpdateSubTabPrev_OnEnter()
	local oldpageWL = GarbageMan.WLselectedPage local oldpageBL = GarbageMan.BLselectedPage
	if(oldpageWL ~= 1) then 
		--preloading WhiteList items on prev page
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.WLselectedPage = oldpageWL
		GarbageMan.GarbageTabButton_Update(true)
	end
	if(oldpageBL ~= 1) then 
		--preloading BlackList items on prev page
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
		GarbageMan.GarbageTabButton_Update(true)
		GarbageMan.BLselectedPage = oldpageBL
		GarbageMan.GarbageTabButton_Update(true)
	end
end

--Purpose: Updates GarbageMan Tab based on selected GarbageMan subtab and page numer
--Arguments: [table] list of whitelist or blacklist item; [integer] page number of selected GarbageMan subtab
--Returns: Nothing
function GarbageMan.UpdatePage(list, list_page)
	local num_items = GarbageMan.GetListLength(list)
	if( num_items > BUYBACK_ITEMS_PER_PAGE) then 
		if(list_page == 1) then 
			GarbageMan.prev_button:Disable()
		else
			GarbageMan.prev_button:Enable()
		end
		if (list_page == math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) or num_items == 0) then
			GarbageMan.next_button:Disable()
		else
			GarbageMan.next_button:Enable()
		end
			GarbageMan.pageText:SetText("Page "..list_page.." of "..math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE))

		GarbageMan.pageText:Show()
		MerchantPageText:Hide()
		GarbageMan.prev_button:Show()
		GarbageMan.next_button:Show()
	else
		GarbageMan.pageText:Hide()
		MerchantPageText:Hide()
		GarbageMan.prev_button:Hide()
		GarbageMan.next_button:Hide()
	end
end

--Purpose: Updates page number and loads the previous page
--Returns: Nothing
function GarbageMan.PrevPage()
	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
		GarbageMan.UpdatePage(GarbageMan_ItemWhiteList, GarbageMan.WLselectedPage)
	else
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
		GarbageMan.UpdatePage(GarbageMan_ItemBlackList, GarbageMan.BLselectedPage)
	end
end

--Purpose: Updates page number and loads the next page
--Returns: Nothing
function GarbageMan.NextPage()
	
	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		GarbageMan.WLselectedPage = GarbageMan.WLselectedPage + 1 
		GarbageMan.UpdatePage(GarbageMan_ItemWhiteList, GarbageMan.WLselectedPage)
	else
		GarbageMan.BLselectedPage = GarbageMan.BLselectedPage + 1 
		GarbageMan.UpdatePage(GarbageMan_ItemBlackList, GarbageMan.BLselectedPage)
	end
end

--Purpose: Creates and initializes page buttons for each GarbageMan subtab
--Returns: Nothing
function GarbageMan.generate_PageButtons()
	GarbageMan.prev_button = CreateFrame("Button", GarbageMan.name..".PrevButton", MerchantFrame, "GarbageManPrevButtonTemplate")
	GarbageMan.prev_button:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 42, 0)
	GarbageMan.prev_button:SetScript("Onclick", function(self) GarbageMan.PrevPage() GarbageMan.GarbageTabButton_Update(false)end )
	--predictive page loading
	GarbageMan.prev_button:SetScript("OnEnter", GarbageMan.UpdateSubTabPrev_OnEnter)
	GarbageMan.prev_button:SetScript("OnLeave", GarbageMan.UpdateSubTabPrev_OnEnter)
	GarbageMan.prev_button:SetScript("PostClick", GarbageMan.UpdateSubTabPrev_OnEnter)
	GarbageMan.prev_button:Hide()

	GarbageMan.next_button = CreateFrame("Button", GarbageMan.name..".NextButton", MerchantFrame, "GarbageManNextButtonTemplate")
	GarbageMan.next_button:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMRIGHT", -42, 0)
	GarbageMan.next_button:SetScript("Onclick", function(self) GarbageMan.NextPage() GarbageMan.GarbageTabButton_Update(false)end)
	--predictive page loading
	GarbageMan.next_button:SetScript("OnEnter", GarbageMan.UpdateSubTabNext_OnEnter)
	GarbageMan.next_button:SetScript("OnLeave", GarbageMan.UpdateSubTabNext_OnEnter)
	GarbageMan.next_button:SetScript("PostClick", GarbageMan.UpdateSubTabNext_OnEnter)
	GarbageMan.next_button:Hide()

	--creating page text
	GarbageMan.pageText = _G["MerchantFrameTab"..MerchantFrame.numTabs]:CreateFontString(GarbageMan.name..".PageText", "BORDER", "GameFontNormal")
	GarbageMan.pageText:SetPoint("CENTER", MerchantFrame, "BOTTOM", 0, 15)
end

--Purpose: Creates and initializes GarbageMan buttons
--Returns: Nothing
function GarbageMan.generate_GarbageButtons()
 	GarbageMan.garbageButton = CreateFrame("Button", GarbageMan.name..".SellButton", MerchantFrameInset, "GarbageManItemButtonTemplate")
	GarbageMan.garbageButtonTooltip = CreateFrame("GameTooltip", GarbageMan.name..".ButtonTooltip", MerchantFrame, "GameTooltipTemplate")
	GarbageMan.filterButton = CreateFrame("Button", GarbageMan.name..".ItemAutoFilterButton", MerchantFrameInset, "GarbageManBagItemAutoFilterButtonTemplate")
	GarbageMan.filterButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", -15, 15)
	GarbageMan.filterButton:Show()
end

--Purpose: Adds item to blacklist/whitelist depending on GarbageMan subtab selected when the user left-clicks the item in bags
--Returns: Nothing
function GarbageMan.ContainerFrameItemButton_OnClick(self, button)
	if ( MerchantFrame:IsShown() ) then
		if(button == "LeftButton") then 
			if(MerchantFrame.selectedTab == 3 and _G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
				local itemID = select(10, GetContainerItemInfo(self:GetParent():GetID(), self:GetID()))
				if(itemID) then
					if(GarbageMan_ItemBlackList[itemID]) then
						GarbageMan_ItemBlackList[itemID] = nil
					end
					local itemName = GetItemInfo(itemID)	

					GarbageMan_ItemWhiteList[itemID] = itemName	
					GarbageMan.sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
					MerchantFrame_Update()

					if(self:GetParent():GetID() ~= 0) then 
						PutItemInBag(self:GetParent():GetID() + 19) --bag argument starts from 20-23, but bag id starts from 0-3
					else
						PutItemInBackpack()
					end
				end
					
			end
			if(MerchantFrame.selectedTab == 3 and _G[GarbageMan.name.."ContainerFrame"].selectedTab == 2) then
				local itemID = select(10, GetContainerItemInfo(self:GetParent():GetID(), self:GetID()))
				if(itemID) then
					if(GarbageMan_ItemWhiteList[itemID]) then
							GarbageMan_ItemWhiteList[itemID] = nil
					end
					local itemName = GetItemInfo(itemID)	

					GarbageMan_ItemBlackList[itemID] = itemName
					GarbageMan.sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
					MerchantFrame_Update()
					if(self:GetParent():GetID() ~= 0) then 
						PutItemInBag(self:GetParent():GetID() + 19) --bag argument starts from 20-23, but bag id starts from 0-3
					else
						PutItemInBackpack()
					end
				end
			end
		end

	end
end

--Purpose: Retrieves item from table (WhiteList or BlackList)
--Arguments: [table] WhiteList or BlackList; [integer] item's itemID; [array] item-ids pre-sorted from the first argument's keys (WhiteList/BlackList)
--Returns: [integer] item-id; [string] item's name
function GarbageMan.GetListItemInfo(table, index, sortedKeys)
	if(sortedKeys[index]) then 
		return sortedKeys[index], table[sortedKeys[index]]
	else 
		return nil, nil
	end
end

--Purpose: Updates Last item on GarbageMan page
--Returns: Nothing
function GarbageMan.UpdateLastItem()
	local i = 12
	local itemButton = _G["MerchantItem"..i.."ItemButton"]
	local item = _G["MerchantItem"..i]
	local index

	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then 
		t = GarbageMan_ItemWhiteList
		index = (((GarbageMan.WLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i)
		sortedKeys = GarbageMan.sortedKeysWL
	else
		t = GarbageMan_ItemBlackList
		index = (((GarbageMan.BLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i)
		sortedKeys = GarbageMan.sortedKeysBL
	end

	local itemID, name = GarbageMan.GetListItemInfo(t, index, sortedKeys)
	if(itemID) then
			
		_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide()

		local texture = select(10, GetItemInfo(itemID))
		local itemLink = select(2, GetItemInfo(itemID))
		itemButton.link = itemLink

		_G["MerchantItem"..i.."Name"]:SetText(name)

		SetItemButtonTexture(itemButton, texture)
		itemButton.UpdateTooltip = GarbageMan.MerchantItemButton_OnEnter
		MerchantFrameItem_UpdateQuality(item, itemLink)
		itemButton:SetID(index)
		SetItemButtonCount(itemButton, 1)
		itemButton:Show()
	end
end

--Purpose: Removes item clicked from WhiteList/BlackList (depending on GarbageMan selected tab) on Merchant window
--Arguments: [table] WhiteList or BlackList; [integer] item's itemID; [array] item-ids pre-sorted from the first argument's keys (WhiteList/BlackList)
--Returns: Nothing
function GarbageMan.MerchantItemButton_OnClick(self, button)
	if(MerchantFrame.selectedTab == 3) then
		if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
			local itemID, itemName = GarbageMan.GetListItemInfo(GarbageMan_ItemWhiteList, self:GetID(), GarbageMan.sortedKeysWL)
			if(itemName) then 
				GarbageMan_ItemWhiteList[itemID] = nil
				local num_items = GarbageMan.GetListLength(GarbageMan_ItemWhiteList)
				if( GarbageMan.WLselectedPage > math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) and GarbageMan.WLselectedPage ~= 1) then  --if we removed enough not have enough items fill the page
					GarbageMan.WLselectedPage = GarbageMan.WLselectedPage - 1
				end
				GarbageMan.sortedKeysWL = GarbageMan.SortAssociativeArray(GarbageMan_ItemWhiteList)
				MerchantFrame_Update()
			end
		end
		if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 2) then
			local itemID, itemName = GarbageMan.GetListItemInfo(GarbageMan_ItemBlackList, self:GetID(), GarbageMan.sortedKeysBL)
			if(itemName) then 
				GarbageMan_ItemBlackList[itemID] = nil
				local num_items = GarbageMan.GetListLength(GarbageMan_ItemBlackList)
				if( GarbageMan.BLselectedPage > math.ceil(num_items / BUYBACK_ITEMS_PER_PAGE) and GarbageMan.BLselectedPage ~= 1) then --if we removed enough not have enough items fill the page
					GarbageMan.BLselectedPage = GarbageMan.BLselectedPage - 1
				end
				GarbageMan.sortedKeysBL = GarbageMan.SortAssociativeArray(GarbageMan_ItemBlackList)
				MerchantFrame_Update()
				
			end
		end

	end
end

--Purpose: Initializes Lists dropdown menu
--Arguments: [GarbageMan Object] self; [integer] level determines which option in dropdown menu is selected
--Returns: Nothing
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

--Purpose: Creates and initializes GarbageMan subtab buttons
--Returns: Nothing
function GarbageMan.Generate_SubTabButtons()
	GarbageMan.GarbageMan_Container = CreateFrame("Frame", GarbageMan.name.."ContainerFrame", MerchantFrame)
	PanelTemplates_SetNumTabs(GarbageMan.GarbageMan_Container, 2)

	local tab1 = CreateFrame("Button", GarbageMan.name.."ContainerFrameTab".. 1, GarbageMan.GarbageMan_Container,"TabButtonTemplate")
	tab1:SetPoint("BOTTOMLEFT", MerchantFrameInset, "TOPLEFT", 50, 0)
	--tab1:SetPoint("BOTTOMLEFT", MerchantFrameInset, "TOPLEFT", 0, 0) Feature not yet ready! No nead to make room for it!
	tab1:SetText("WhiteList")
	tab1:SetID(1)
	PanelTemplates_TabResize(tab1)

	tab1:SetScript("OnEnter", function(self) GameTooltip:SetOwner( self, "ANCHOR_RIGHT") GameTooltip:SetText("Left-Click Items to add to WhiteList") end)
	tab1:SetScript("OnLeave", GameTooltip_Hide)
	tab1:SetScript("OnClick", function(self) PanelTemplates_SetTab(GarbageMan.GarbageMan_Container, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)
	tab1:Hide()
	
	local tab2 = CreateFrame("Button", GarbageMan.name.."ContainerFrameTab".. 2, GarbageMan.GarbageMan_Container,"TabButtonTemplate")
	tab2:SetPoint("TOPLEFT", tab1, "TOPRIGHT", -5, 0)
	tab2:SetText("BlackList")
	tab2:SetID(2)
	PanelTemplates_TabResize(tab2)

	tab2:SetScript("OnEnter",  function(self) GameTooltip:SetOwner( self, "ANCHOR_RIGHT") GameTooltip:SetText("Left-Click Items to add to BlackList") end)
	tab2:SetScript("OnLeave", GameTooltip_Hide)
	tab2:SetScript("OnClick", function(self) PanelTemplates_SetTab(GarbageMan.GarbageMan_Container, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)

	tab2:Hide()
	PanelTemplates_SetTab(GarbageMan.GarbageMan_Container, 1)
end 

--Purpose: Adds corresponding gametooltip for item buttons displayed
--Arguments: [button] item buttons displayed on GarbageMan
--Returns: Nothing
function GarbageMan.MerchantItemButton_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	if ( MerchantFrame.selectedTab == 1 ) then
		GameTooltip:SetMerchantItem(button:GetID())
		GameTooltip_ShowCompareItem(GameTooltip)
		MerchantFrame.itemHover = button:GetID()
	elseif(MerchantFrame.selectedTab == 2) then
		GameTooltip:SetBuybackItem(button:GetID())
		if ( IsModifiedClick("DRESSUP") and button.hasItem ) then
			ShowInspectCursor()
		else
			ShowBuybackSellCursor(button:GetID())
		end
	
	else
		GarbageMan.UpdateLastItem() --loading item that most likely to be changed
		GameTooltip:SetHyperlink(button.link)
		ShowInspectCursor()
	end
	
end

--Purpose: Clears the page of Merchant and BuyBack related UI elements
--Returns: Nothing
function GarbageMan.ClearPage()
	-- Hide all merchant related items
	MerchantRepairAllButton:Hide()
	MerchantRepairItemButton:Hide()
	MerchantBuyBackItem:Hide()
	MerchantPrevPageButton:Hide()
	MerchantNextPageButton:Hide()
	MerchantFrameBottomLeftBorder:Hide()
	MerchantFrameBottomRightBorder:Hide()
	MerchantRepairText:Hide()
	MerchantPageText:Hide()
	MerchantExtraCurrencyBg:Hide()
	MerchantExtraCurrencyInset:Hide()
	MerchantMoneyFrame:Hide()
	MerchantMoneyBg:Hide()
	MerchantMoneyInset:Hide()
	MerchantGuildBankRepairButton:Hide()
	MerchantFrameLootFilter:Hide()
	--Hide buyback background
	BuybackBG:Hide()
end

--Purpose: Updates GarbageMan UI if they have alternate currencies based on GarbageMan page is being viewed
--Returns: Nothing
function GarbageMan.UpdateCurrency(onGarbageTab)
	local currencies = { GetMerchantCurrencies() }
	local numCurrencies = #currencies
	for index = 1, numCurrencies do
		local tokenButton = _G["MerchantToken"..index]
		if(onGarbageTab) then 
			_G["MerchantToken"..index]:Hide()
		else
			if(_G["MerchantToken"..index]) then 
				_G["MerchantToken"..index]:Show()
					
			end
		end
	end
end

--Purpose: Clears the page of GarbageMan related UI elements and resets Merchant/BuyBack UI elements
--Returns: Nothing
function GarbageMan.ResetMerchant_BuyBackPage()
	local currencies = { GetMerchantCurrencies() }
	local numCurrencies = #currencies
	MerchantMoneyFrame:Show()
	MerchantMoneyBg:Show()
	MerchantMoneyInset:Show()
	MerchantFrameLootFilter:Show()
	MerchantFramePortrait:Show()
	MerchantFramePortraitFrame:Show()
	--_G["GarbageMan.ListsDropDownMenu"]:Hide() Feature not yet added!

	if(numCurrencies >= 1) then 
		MerchantExtraCurrencyBg:Show()
		MerchantExtraCurrencyInset:Show()
		GarbageMan.filterButton:ClearAllPoints()
		GarbageMan.filterButton:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 140, -30)
	else
		GarbageMan.filterButton:ClearAllPoints()
		GarbageMan.filterButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", -20, 14)
	end

	GarbageMan.UpdateCurrency(false)
	GarbageMan.pageText:Hide()
	GarbageMan.prev_button:Hide()
	GarbageMan.next_button:Hide()
	_G[GarbageMan.name.."ContainerFrameTab".. 1]:Hide()
	_G[GarbageMan.name.."ContainerFrameTab".. 2]:Hide()
end

--Purpose: Builds the framework/background for GarbageMan UI specific elements
--Returns: Nothing
function GarbageMan.TemplateGarbageManPage()
	MerchantNameText:SetText("GarbageMan") 
	MerchantFramePortrait:SetTexture("Interface/Garrison/Portraits/EnemyPortrait_1693")
	MerchantItem11:Show()
	MerchantItem12:Show()
	
	GarbageMan.UpdateCurrency(true)
	GarbageMan.filterButton:ClearAllPoints()
	GarbageMan.filterButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", -50, 14)
	--_G["GarbageMan.ListsDropDownMenu"]:Show() Feature not yet added!

	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -15)
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -15)
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -15)
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -15)
	_G[GarbageMan.name.."ContainerFrameTab".. 1]:Show()
	_G[GarbageMan.name.."ContainerFrameTab".. 2]:Show()
end 

--Purpose: Updates GarbageMan Page on the selected tab
--Returns: Nothing
function GarbageMan.GarbageTabButton_Update(preview)
	if(MerchantFrame.selectedTab == 1 or MerchantFrame.selectedTab == 2) then
		GarbageMan.ResetMerchant_BuyBackPage()
		return
	end

	GarbageMan.ClearPage()
	GarbageMan.TemplateGarbageManPage()

	local t; local WLpage; local sortedKeys

	if(_G[GarbageMan.name.."ContainerFrame"].selectedTab == 1) then
		t = GarbageMan_ItemWhiteList
		sortedKeys = GarbageMan.sortedKeysWL
		WLpage = true
	else
		t = GarbageMan_ItemBlackList
		sortedKeys = GarbageMan.sortedKeysBL
		WLpage = false
	end

	--renders only if not preloading
	if(WLpage and not preview) then 
		GarbageMan.UpdatePage(t, GarbageMan.WLselectedPage)
	elseif(not preview) then
		GarbageMan.UpdatePage(t, GarbageMan.BLselectedPage)
	end
	
	local i = 1

	for i=1, BUYBACK_ITEMS_PER_PAGE do

		local itemButton = _G["MerchantItem"..i.."ItemButton"]
		local item = _G["MerchantItem"..i]
		_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide()
		SetItemButtonNameFrameVertexColor(item, 0.5, 0.5, 0.5)
		SetItemButtonSlotVertexColor(item, 1.0, 1.0, 1.0)
		SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
		SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
		_G["MerchantItem"..i.."Name"]:SetText("")
		_G["MerchantItem"..i.."MoneyFrame"]:Hide()
		itemButton:Hide()

		local index
		if(WLpage) then 
			index = (((GarbageMan.WLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i)
		else
			index = (((GarbageMan.BLselectedPage - 1) * BUYBACK_ITEMS_PER_PAGE) + i)
		end

		local itemID, name = GarbageMan.GetListItemInfo(t, index, sortedKeys)
		if(itemID) then
			
			_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide()

			local texture = select(10, GetItemInfo(itemID))
			local itemLink = select(2, GetItemInfo(itemID))
			itemButton.link = itemLink

			_G["MerchantItem"..i.."Name"]:SetText(name)

			SetItemButtonTexture(itemButton, texture)
			itemButton.UpdateTooltip = GarbageMan.MerchantItemButton_OnEnter
			MerchantFrameItem_UpdateQuality(item, itemLink)
			itemButton:SetID(index)
			SetItemButtonCount(itemButton, 1)
			itemButton:Show()
		end
	end
end

--Purpose: Creates and initializes GarbageMan Tab buton
--Returns: Nothing
function GarbageMan.generate_GarbageTabButton()
	garbageTab_button = CreateFrame("Button", "MerchantFrameTab"..MerchantFrame.numTabs+1, MerchantFrame, "CharacterFrameTabButtonTemplate", MerchantFrame.numTabs +1)
	garbageTab_button:SetPoint("LEFT", MerchantFrameTab2, "RIGHT", -16, 0)
	garbageTab_button:SetText("GarbageMan")

	--Preloading
	garbageTab_button:SetScript("OnEnter", function(self) GarbageMan.UpdateMainTab_OnEnter(self) end)
	garbageTab_button:SetScript("OnLeave", GameTooltip_Hide)
	garbageTab_button:SetScript("OnClick", function(self) PanelTemplates_SetTab(MerchantFrame, self:GetID()) GarbageMan.GarbageTabButton_Update(false)end)
	
	garbageTab_button:SetID(MerchantFrame.numTabs+1)
	
	PanelTemplates_TabResize(garbageTab_button)
	PanelTemplates_SetNumTabs(MerchantFrame, MerchantFrame.numTabs + 1)
end

--Purpose: Creates the UI for GarbageMan
--Returns: Nothing
function GarbageMan:generateUI()
	local garbageManMerchantFrame = CreateFrame("Frame", "GarbageManMerchantFrame", MerchantFrame, nil, 5)
	garbageManMerchantFrame:SetID(MerchantFrame.numTabs+1)
	GarbageMan.generate_GarbageButtons()
	GarbageMan.generate_GarbageTabButton()
	GarbageMan.Generate_SubTabButtons()
	GarbageMan.generate_PageButtons()
	--GarbageMan.generate_ListDropDownMenus() Feature not yet added!
end

