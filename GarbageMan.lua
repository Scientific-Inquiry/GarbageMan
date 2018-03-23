local NUM_BAG_SLOTS = 4 --[5 bags -> 0-4]--
local NUM_CONTAINER_FRAMES = 13 

local total_profit = 0
local MAX_ILVL = 1000
local MAXLEVEL = 110

GarbageMan.garbage_items = {} --[Item] list keeping track of garbage to sell 

local SLOTS_MAPPING = --mapping inventory item-type to iventory-id
{
	["INVTYPE_HEAD"] 			= 1,
	["INVTYPE_NECK"] 			= 2,
	["INVTYPE_SHOULDER"] 		= 3,
	["INVTYPE_BODY"]			= 4,
	["INVTYPE_CHEST"] 			= 5,
	["INVTYPE_ROBE"] 			= 5,
	["INVTYPE_WAIST"] 			= 6,
	["INVTYPE_LEGS"]			= 7,
	["INVTYPE_FEET"]			= 8,
	["INVTYPE_WRIST"]			= 9,
	["INVTYPE_HAND"] 			= 10,
	["INVTYPE_FINGER"] 			= {11,12},
	["INVTYPE_TRINKET"]			= {13,14},
	["INVTYPE_CLOAK"] 			= 15,
	["INVTYPE_WEAPON"]			= {16,17},
	["INVTYPE_SHIELD"] 			= 17,
	["INVTYPE_2HWEAPON"] 		= 16,
	["INVTYPE_WEAPONMAINHAND"] 	= 16,
	["INVTYPE_WEAPONOFFHAND"] 	= 17,
	["INVTYPE_HOLDABLE"] 		= 17,
	["INVTYPE_RANGED"]			= 18,
	["INVTYPE_THROWN"]			= 18,
	["INVTYPE_RANGEDRIGHT"]		= 18,
	["INVTYPE_RELIC"] 			= 18,
	["INVTYPE_TABARD"] 			= 19
}

--defining Item object
local Item = {
	id = 0,
	bagId = 0, 
	slot = 0,
	sell_price = 0,
	count = 0,
	refundable = false,
	tradeable = false,
	link = nil
}

--defining new constructor for Items
function Item:new (id, name, bagId, slot, sell_price, count, refundable, tradeable, expansionId, link)
   local o =  {}
   self.__index = self
   o.id = id
   o.name = name
   o.bagId = bagId
   o.slot = slot
   o.sell_price = sell_price or 0
   o.count = count or 0
   o.refundable = refundable or false
   o.tradeable = tradeable or false
   o.expansionId = expansionId or 0
   o.link = link
   setmetatable(o, self)
   return o
end

--Purpose: to retrieve item information
--Arguments: [integer] item_quality is the item's rarity; [integer] bag and [integer] slot indicates location of item in inventory
--Returns item's boolean table info {soulbound, accountbound, refundable, tradeable, itemlvl}
local function GetStatus(item_quality, bag, slot)
	local itemLvl = 0; local soulbound = false; local accountbound = false
	local refundable = false; local tradeable = false

	if(item_quality ==0) then --do not bother scanning if it is a trash item
		return soulbound, accountbound, refundable, tradeable, itemLvl
	end
	GarbageMan.ScanningTooltip:ClearLines()
	GarbageMan.ScanningTooltip:SetBagItem(bag, slot)
	local num_lines = GarbageMan.ScanningTooltip:NumLines()
	local refundMsg = strsplit("%", REFUND_TIME_REMAINING); local tradeMsg =  strsplit("%", BIND_TRADE_TIME_REMAINING); local itemLvlMsg = strsplit("%", ITEM_LEVEL).."(%d+)"
	
	if(num_lines == 0) then --if there is no information to scan, return defaults
		return soulbound, accountbound, refundable, tradeable, itemLvl
	end

	local status 
	for i = 1, select("#", GarbageMan.ScanningTooltip:GetRegions()) do
        local region = select(i, GarbageMan.ScanningTooltip:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            status = region:GetText() 

            if(status == ITEM_SOULBOUND) then 
				soulbound = true
			end
			if(status and string.match(status, ITEM_ACCOUNTBOUND)) then
				accountbound = true
			end
            if(status and string.match(status, refundMsg)) then 
				return soulbound, accountbound, true, tradeable, itemLvl --refund msg is the last line of tooltip
			end

			if(status and string.match(status, tradeMsg)) then
				return soulbound, accountbound, refundable, true, itemLvl --trade msg is the last line of tooltip
			end

			if(status and string.match(status, itemLvlMsg)) then
				itemLvl = tonumber(string.match(status, itemLvlMsg))
			end

        end
    end
	return soulbound, accountbound, refundable, tradeable, itemLvl

end

--Purpose: To take copper value and convert into gold, silver, and copper
--Agruments: [integer] Item's copper value
--Returns: copper value equivalent table {[int] gold, [int] silver, [int] copper}
local function ConvertCoppertoStandard(total_copper)
	local copper = total_copper % 100
    total_copper = (total_copper - copper) / 100
    local silver = total_copper % 100
    local gold = (total_copper - silver) / 100
	return gold, silver, copper
end 

--Purpose: Desaturates and disables sell button if no garbage is found
--Returns: table {[boolean] indicating if garbage was found; [integer] total profit (in copper value) of garbage items marked in inventory}
function GarbageMan.HasGarbage()
	local num_garbage, profit = GarbageMan.FindGarbage(false)
	if(num_garbage == 0) then
		SetDesaturation(GarbageManButtonIcon,true)
		GarbageMan.garbageButton:Disable()
		return false, profit
	else 
		SetDesaturation(GarbageManButtonIcon,false)
		GarbageMan.garbageButton:Enable()
	end
	return true, profit
end

--Purpose: Sells items in inventory that are considered garbage
--Returns: [integer] Profit (in copper value) that will be gained from selling garbage items
function GarbageMan.SellGarbage(bagId, slot)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	GarbageMan.FindGarbage(true)
	for i,item in ipairs(GarbageMan.garbage_items) do
		if(item.refundable and GarbageMan_Auto_Refund == true) then --sell refundable item
			UseContainerItem(item.bagId, item.slot)
			_G["StaticPopup1Button1"]:Click("LeftButton")
		elseif(item.tradeable and GarbageMan_Auto_Bind == true) then --sell tradeable item
			UseContainerItem(item.bagId, item.slot)
			_G["StaticPopup1Button1"]:Click("LeftButton")
		elseif(item.sell_price== 0) then --merchant does not want item, must delete
			PickupContainerItem(item.bagId, item.slot)
			DeleteCursorItem()
		else
			UseContainerItem(item.bagId, item.slot)
		end
		total_profit = total_profit + item.sell_price * item.count
	end

	if(total_profit ~= 0) then 
		local gold, silver, copper = ConvertCoppertoStandard(total_profit)
		print("|cFF00FF00GarbageMan earned|r "..gold.."|cFFFFFF00g|r "..silver.."|cFFFFFF00s|r "..copper.."|cFFFFFF00c|r ")
	end

	--reset values for next call
	total_profit = 0
	GarbageMan.garbage_items = {}
	collectgarbage()

	return profit
end

--Purpose: Display updates based on merchant ability to repair and guild repair; Garbage items in inventory; Merchant page; filter toggle for garbage items]
--Arguments: [GarbageMan Object] self; [integer] dt is time in seconds until OnUpdate is called
--Returns: Nothing
local function GarbageMan_OnUpdate(self, dt)
	local relativeObj
	local currentPage = MerchantFrame.selectedTab

	if(currentPage == 1) then
		GarbageMan.garbageButton:Show()
		GarbageMan.tutorialButton:Show()
		local _, profit = GarbageMan.HasGarbage()

		--width and height are dependent on size of the anchor button
		local width
		local height

		if CanMerchantRepair() then
			GarbageMan.garbageButton:SetPoint("TOPRIGHT", MerchantRepairItemButton, "TOPLEFT")
			width = MerchantRepairItemButton:GetWidth()
			height = MerchantRepairItemButton:GetHeight() 
		else
			GarbageMan.garbageButton:SetPoint("TOPRIGHT", MerchantBuyBackItemItemButton, "TOPLEFT", -16, 0)
			width = MerchantBuyBackItemItemButton:GetWidth()
			height = MerchantBuyBackItemItemButton:GetHeight() 
		end

		MerchantRepairText:SetText("")
		GarbageMan.garbageButton:SetWidth(width)
		GarbageMan.garbageButton:SetHeight(height)
		
		--must update profit as bag updates
		GarbageMan.garbageButton:SetScript("OnEnter", function(self) GarbageMan.garbageButtonTooltip:SetOwner(GarbageMan.garbageButton,"ANCHOR_RIGHT")
			GarbageMan.garbageButtonTooltip:SetText("Sell All Garbage")  if(profit > 0) then SetTooltipMoney(GarbageMan.garbageButtonTooltip, profit) end
			GarbageMan.garbageButtonTooltip:Show() end)
		GarbageMan.garbageButton:SetScript("OnLeave", function(self) GarbageMan.garbageButtonTooltip:Hide() end)

	elseif(currentPage == 3) then
		GarbageMan.tutorialButton:Show()
		GarbageMan.HasGarbage()
		GarbageMan.garbageButton:Hide()
	else
		GarbageMan.tutorialButton:Hide()
		GarbageMan.garbageButton:Hide()
	end
	if(currentPage == 1 or currentPage == 2) then
		_G[GarbageMan.name.."ContainerFrameTab".. 1]:Hide()
		_G[GarbageMan.name.."ContainerFrameTab".. 2]:Hide()
	end
	 GarbageMan.FilterBagsUpdate()
end

--Purpose: Get an item's item-level (NOTE: item-level from API is not reliable for timewarped/upgraded gear)
--Arguments: [itemString] link of item
--Returns: [integer] item-level
function GarbageMan.GetItemLevel(link) 
	local itemLvl = 0
	if(item_quality ==0) then --if quality is garbage, do not bother trying to get its item-level
		return itemLvl
	end

	GarbageMan.ScanningTooltip:ClearLines()
	GarbageMan.ScanningTooltip:SetHyperlink(link)
	local itemLvlMsg = strsplit("%", ITEM_LEVEL).."(%d+)"

	if(line == 0) then --there are no lines to scan, return default item-level
		return  itemLvl
	end

	local status 
	for i = 1, select("#",GarbageMan.ScanningTooltip:GetRegions()) do
        local region = select(i, GarbageMan.ScanningTooltip:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            status = region:GetText() 
			if(status and string.match(status, itemLvlMsg)) then
				itemLvl = tonumber(string.match(status, itemLvlMsg))
			end
        end
    end
	return itemLvl
end

--Purpose: Get an item-level of equipped item in a specific slot
--Arguments: [string] name of slot; [string] item's name
--Returns: [integer] item's item-level
local function GetEquippedItemLevel(slot, name)
	
	local ilvl = math.huge
	local slotId = SLOTS_MAPPING[slot]

	if(_G[slot] == INVTYPE_TABARD) then --if tabard slot return 0
		return 0
		

	elseif(_G[slot] == INVTYPE_FINGER or _G[slot] == INVTYPE_TRINKET or _G[slot] == INVTYPE_WEAPON) then 

		for k = 1, 2 do

			local itemlink = GetInventoryItemLink(PLAYER, SLOTS_MAPPING[slot][k])

			local check_ilvl 
			if(not itemlink) then --if you do not have anything equipped in that slot
				check_ilvl = 0

			else
				check_ilvl = GarbageMan.GetItemLevel(itemlink)
			end

			if(check_ilvl < ilvl) then--find the least item level of the two slots
				ilvl = check_ilvl

			end

		end
		return ilvl
	else
		
		local itemlink = GetInventoryItemLink(PLAYER, slotId)
		if(not itemlink) then --if you do not have anything equipped in that slot
			return 0
		end

		ilvl = GarbageMan.GetItemLevel(itemlink)
	end
	
	return ilvl
end

--Feature not ready yet!
--Purpose: Check if crafting reagent is from a lower expansion
--Arguments: [string] item's name; [string] slot that item is in (if equipable); [integer] expansion-id (0-6)
--Returns: [boolean] indicating if the crafting item is from a lower expansion
local function IsLowerExpansion(name, slot, expanID, iscrafting)
	if(GarbageMan_Expansion_Choice ~= "None") then

		local lower_equip = expanID < (expansion_lookuptable[GarbageMan_Expansion_Choice] -1) and (_G[slot] ~= INVTYPE_TABARD and not string.match(name,"Fishing Pole"))
		local lower_crafting = EXPANSIONS_OPTIONS[GarbageMan_Expansion_Choice]
		return lower_equip
	end
	return false
end

--Purpose: Checks item is equippable gear
--Arguments: [string] the item's item-type; [integer] item's rarity; [string] slot that item equips to 
--Returns: [boolean] indicating if it is equippable gear
function GarbageMan.IsEquippableGear(itemType, quality, itemSlot)
	return ((itemType == ARMOR or itemType == WEAPON) and quality < 5 and (_G[itemSlot] ~= INVTYPE_TABARD))
end

--Purpose: Checks to see if item is lower level than equipped equivalent slot
--Arguments: [itemString] item's hyperlink; [integer] bag and [integer] slot indicating item location in bags; [integer] item's item-level
--Returns: [boolean] indicating if the item is low-level gear
local function IsLowerLevelGear(itemlink, bag, slot, effectiveILvl)
	if(GarbageMan_Auto_Sell_LowerGear or GarbageMan_Sell_Threshold) then --if either of these settings are enabled
		local name, _, quality, ilvl, _, itemType, _, _, itemSlot = GetItemInfo(itemlink)
		if(quality == 0) then --gear is not worthy enough for you
			return false
		end
		if( GarbageMan.IsEquippableGear(itemType, quality, itemSlot)) then 
			if(effectiveILvl < GetEquippedItemLevel(itemSlot, name)) then
				return true
			elseif (effectiveILvl < GarbageMan_SetIlvl and GarbageMan_Sell_Threshold) then 
				return true
			else
				return false
			end
		else --it is not gear
			return false
		end
	end 
	return false
end

--declared for InsertGarbageList and FindGarbage to use
local num_garbage = 0
local profit = 0

--Purpose: Add garbage items to GarbageMan.garbage_items to sell/delete when the sell button is pressed
--Arguments: [boolean] indicating if garbageman is selling now; [Item Object] garbage item to insert; [integer] number of slots the bag has that contains this item
--Returns: Nothing
local function insertGarbageList(selling, item, NUM_SLOTS)
	num_garbage = num_garbage + 1

	if(not item.refundable) then
		profit = profit + item.sell_price * item.count
	end
	_G["ContainerFrame"..(item.bagId+1).."Item"..(math.abs(NUM_SLOTS -(item.slot))+1)].JunkIcon:SetShown(MerchantFrame:IsShown())

	if(selling) then
		table.insert(GarbageMan.garbage_items, item)
	end
end

--Purpose: Checks to see if item is not in whitelist and it is a garbage item
--Arguments: [integer] itemSellPrice, price vendor is willing to pay for item; [integer] item's unique item-id; [integer] item's rarity
--Returns: [boolean] indicating if item is not on whitelist and it is garbage
local function isNotWhiteList(itemSellPrice, itemID, quality)
	return ((itemSellPrice ~= 0 and GarbageMan_ItemWhiteList[itemID] == nil and GarbageMan_WhiteList) or (itemSellPrice ~= 0 and not GarbageMan_WhiteList) or (GarbageMan_ItemBlackList[itemID] ~= nil and GarbageMan_BlackList)) --or (itemSellPrice ~= 0  and not GarbageMan_WhiteList))
end 

--Purpose: Checks to see if item is lower level gear or it is still a garbage item
--Arguments: [integer] item's unique itemID; [integer] item's item-level; [integer] item's rarity; [integer] bag that item is in; [integer] slot that item is in; 
--				[boolean] if it is soulbound; [boolean] if it is accountbound; [boolean] if it is refundable; [boolean] if it is tradeable
--Returns: [boolean] indicating if item is low level gear or it is still a garbage item
local function isLowLevelGarbage(itemID, itemLevel, quality, bag, slot, soulbound, accountbound, refundable, tradeable)
	return ((tradeable and GarbageMan_Auto_Bind) or (refundable and GarbageMan_Auto_Refund) or (soulbound and GarbageMan_Auto_Sell_LowerGear) 
			or (not accountbound and itemLevel < GarbageMan_SetIlvl and GarbageMan_Sell_Threshold) or (GarbageMan_ItemBlackList[itemID] ~= nil) or quality == 0)
end

--Purpose: Checks to see if item can only be deleted and cannot be sold
--Arguments: [integer] item's unique itemID; [integer] itemSellPrice, price vendor is willing to pay for item
--Returns: [boolean] indicates if item can only be deleted
local function canOnlyDelete(itemID, itemSellPrice)
	return GarbageMan_ItemBlackList[itemID] ~= nil and itemSellPrice == 0
end

--Purpose: Filters Bags to show garbage items to be sold/deleted clearly
--Returns: Nothing
function GarbageMan.FilterBagsUpdate()
	for bag = 0, NUM_BAG_SLOTS do
		local NUM_SLOTS = GetContainerNumSlots(bag)
		for slot = 0, NUM_SLOTS do
			local texture, count, locked, quality, readable, lootable, link, isFiltered, _, itemID = GetContainerItemInfo(bag, slot)	
			if(link) then 
				local item_button = _G["ContainerFrame"..(bag+1).."Item"..(math.abs(NUM_SLOTS -(slot))+1)]	
				local borderTexture = _G["ContainerFrame"..(bag+1).."Item"..(math.abs(NUM_SLOTS -(slot))+1).."IconQuestTexture"]
				if(not item_button.JunkIcon:IsShown() and GarbageMan.toggleFilter) then
						item_button.searchOverlay:Show()
						if(not isFiltered and BagItemSearchBox:GetText() ~= "") then --if searching for an item while filter is on
							item_button.searchOverlay:Hide()
						end
				else
					item_button.searchOverlay:Hide()
					if(isFiltered and BagItemSearchBox:GetText() ~= "" and not GarbageMan.toggleFilter) then --if searching for an item while filter is off
							item_button.searchOverlay:Show()
					end

				end
			end
		end
	end
end 

--Purpose: Manages filtering and toggling the for the filter button
--Returns: Nothing
function GarbageMan.FilterBags()
	GarbageMan.toggleFilter = not GarbageMan.toggleFilter
	--toggliing texture
	if(GarbageMan.toggleFilter) then 
		GarbageMan.filterButton:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
		GarbageMan.filterButton:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")

	else
		GarbageMan.filterButton:SetNormalTexture("Interface/ICONS/inv_darkmoon_eye")
		GarbageMan.filterButton:SetPushedTexture("Interface/ICONS/inv_darkmoon_eye")
	end
	--update bags for toggle
	GarbageMan.FilterBagsUpdate()

end

--Purpose: Obtains number of bags that can be used (Note: this is necessary for the Bank)
--Returns: [integer] number of bags available
function GarbageMan.GetNumBankBags()
	local totalBags = 0
	for i=NUM_BAG_FRAMES+1, NUM_CONTAINER_FRAMES, 1 do
		if ( GetContainerNumSlots(i) > 0 ) then		
			totalBags = totalBags +1
		end

end
	return totalBags
end

--Purpose: Checks ot see if the item is blacklisted or it is grey quality (quality = 0)
--Returns: [boolean] indicates if item is blacklisted or it is grey
local function IsBlackListORGrey(itemID, quality)
	return (quality == 0  or (GarbageMan_ItemBlackList[itemID] ~= nil and GarbageMan_BlackList))
end 

--Purpose: Gets the ContainerFrame's associated global for bag and slot
--Arguments: [integer] bag and [integer] slot that specifies the items location in bags; [integer] number of slots in the bag that contains the item
--Returns: [string] name for specific bag and slot for container frame
function GarbageMan.GetContainerFrameBagSlotName(bag, slot, NUM_SLOTS)
	return "ContainerFrame"..(bag+1).."Item"..(math.abs(NUM_SLOTS -(slot))+1)
end

--Purpose: Finds Garbage and appropriately marks them as garbage items in bags | Gold coin for sellable garbage - Red overlay for garbage that can only be deleted
--Returns: [integer] number of garbage items found, [integer] profit (in copper value)
function GarbageMan.FindGarbage(selling)
	local NUM_BAGS 
	if(GarbageMan.isBankOpen) then
		NUM_BAGS = GarbageMan.GetNumBankBags() + NUM_BAG_SLOTS
	else
		NUM_BAGS = NUM_BAG_SLOTS
	end

	num_garbage = 0
	profit = 0
	for bag = 0, NUM_BAGS do 
		local NUM_SLOTS = GetContainerNumSlots(bag)
		for slot = 0, NUM_SLOTS do
			local texture, count, locked, quality, readable, lootable, link, isFiltered, _, itemID = GetContainerItemInfo(bag, slot)		
			if texture then --if item in this slot exists
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemSlot, itemTexture, itemSellPrice, _, _, _, expanID, _, iscrafting = GetItemInfo(link)
				local count = GetItemCount(link)
				local container = GarbageMan.GetContainerFrameBagSlotName(bag, slot, NUM_SLOTS); local borderTexture = _G[container.."IconQuestTexture"]
				local notOnWhitelist = isNotWhiteList(itemSellPrice, itemID, quality)

				if(notOnWhitelist) then --filter whitelist items out
					local isGarbageORBlackList = IsBlackListORGrey(itemID, quality)
					if(isGarbageORBlackList or GarbageMan.IsEquippableGear(itemType, quality, itemSlot)) then --if garbage item or equippable
						local soulbound, accountbound, refundable, tradeable, itemLevel = GetStatus(quality, bag, slot)
						if(isGarbageORBlackList or IsLowerLevelGear(link, bag, slot, itemLevel) and 
							isLowLevelGarbage(itemID, itemLevel, quality, bag, slot, soulbound, accountbound, refundable, tradeable)) then --if garbage item or gear is lowlevel
							if(GarbageMan_Auto_Delete and canOnlyDelete(itemID, itemSellPrice)) then --can only delete item and settings allow deletion
								local temp_item = Item:new(itemID , itemName, bag, slot, itemSellPrice, count, refundable, tradeable, expanID, link)
								borderTexture:SetColorTexture(1, 0, 0, 0.5)
								borderTexture:Show()
								insertGarbageList(selling, temp_item, NUM_SLOTS)
							elseif(not GarbageMan_Auto_Delete and canOnlyDelete(itemID, itemSellPrice)) then  --can only delete item and settings do not allow deletion
								borderTexture:SetColorTexture(0, 0, 0, 0)
								_G[container].JunkIcon:SetShown(false)
							else --sellable garbage
								local temp_item = Item:new(itemID , itemName, bag, slot, itemSellPrice, count, refundable, tradeable, expanID, link)
								if(GarbageMan.isBankOpen) then --if this is the bank instead color the item red (Note: Necessary since bags from bank are associated with the other bags and not the bank)
									borderTexture:SetColorTexture(1, 0, 0, 0.5)
									borderTexture:Show()
								end
								insertGarbageList(selling, temp_item, NUM_SLOTS)
							end

						else
							_G[container].JunkIcon:SetShown(false)
						end
					else
						_G[container].JunkIcon:SetShown(false)
					end
				else
					--quest item is not garbage
					local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag, slot)
					if(questId and not isActive) then 
						borderTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
						borderTexture:Show()
						_G[container].JunkIcon:SetShown(false)
					elseif(questId or isQuestItem) then
						borderTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
						borderTexture:Show()	
					else 
						borderTexture:SetColorTexture(0, 0, 0, 0)
						_G[container].JunkIcon:SetShown(false)
					end

					
				end
			end

		end
	end

	return num_garbage, profit
end

--Purpose: Finds Garbage and appropriately marks them as garbage items in the bank 
--Returns: Nothing
function GarbageMan.BankFrameItemButton_Update(button)
	local container = button:GetParent():GetID()
	local buttonID = button:GetID()
	local texture = button.icon
	local borderTexture
	local _, _, _, quality, _, _, _, isFiltered, _, itemID = GetContainerItemInfo(container, buttonID)
	
	if itemID and not button.isBag then
		local itemName, itemLink, _, itemLevel, _, itemType, _, _, itemSlot, _, itemSellPrice = GetItemInfo(itemID)
		if( button.isBag ) then
			container = -4
		end
		borderTexture = button["IconQuestTexture"]
		local notOnWhitelist = isNotWhiteList(itemSellPrice, itemID, quality)

		if(notOnWhitelist) then --filter whitelist items out
			local isGarbageORBlackList = IsBlackListORGrey(itemID, quality)
			if(isGarbageORBlackList or GarbageMan.IsEquippableGear(itemType, quality, itemSlot)) then --if garbage item or equippable
				local soulbound, accountbound, refundable, tradeable, itemLevel = GetStatus(quality, container, buttonID)
				if(isGarbageORBlackList or (IsLowerLevelGear(itemLink, container, buttonID, itemLevel) and 
					isLowLevelGarbage(itemID, itemLevel, quality, container, buttonID, soulbound, accountbound, refundable, tradeable))) then --if garbage item or gear is lowlevel
								
					if(GarbageMan_Auto_Delete and canOnlyDelete(itemID, itemSellPrice)) then --can only delete item and settings allow deletion
						local temp_item = Item:new(itemID , itemName, container, buttonID, itemSellPrice, count, refundable, tradeable, expanID, link)
						borderTexture:SetColorTexture(1, 0, 0, 0.5)
						borderTexture:Show()
					elseif(not GarbageMan_Auto_Delete and canOnlyDelete(itemID, itemSellPrice)) then --can only delete item and settings do not allow deletion
						borderTexture:SetColorTexture(0, 0, 0, 0)
						borderTexture:Show()
					else --sellable garbage
						local temp_item = Item:new(itemID , itemName, container, buttonID, itemSellPrice, count, refundable, tradeable, expanID, link)
						borderTexture:SetColorTexture(1, 0, 0, 0.5)
						borderTexture:Show()
					end
				else
					borderTexture:SetColorTexture(0, 0, 0, 0)
					borderTexture:Show()

				end
			else
				borderTexture:SetColorTexture(0, 0, 0, 0)
				borderTexture:Show()
			end
		else
			--quest item is not garbage
			local isQuestItem, questId, isActive = GetContainerItemQuestInfo(container, buttonID)
			if(questId and not isActive) then 
				borderTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
				borderTexture:Show()
			elseif(questId or isQuestItem) then
				borderTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
				borderTexture:Show()	
			else 
				borderTexture:SetColorTexture(0, 0, 0, 0)
			end
		end
	end
end

--Purpose: Handles how GarbageMan responds to events
--Arguments: [GarbageMan Object] self, [string] name of event , ... arguments of event
--Returns: Nothing
function GarbageMan.EventHandler(self, event, ...)
	if(event == "MERCHANT_SHOW") then
		GarbageMan.GarbageTabButton_Update()
		GarbageMan.toggleFilter = false
		if(GarbageMan.toggleFilter) then --change textures for toggle
			GarbageMan.filterButton:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
			GarbageMan.filterButton:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
		else
			GarbageMan.filterButton:SetNormalTexture("Interface/ICONS/inv_darkmoon_eye")
			GarbageMan.filterButton:SetPushedTexture("Interface/ICONS/inv_darkmoon_eye")

		end

		if(GarbageMan_Auto_Sell_Garbage) then
			GarbageMan.SellGarbage()
		end
	elseif(event == "MERCHANT_CLOSED") then
		--force close help button 
		HelpPlate_Hide();
		for i = 1, #HELP_PLATE_BUTTONS do
			local button = HELP_PLATE_BUTTONS[i];
			button.box:Hide();
			button:Hide();
		end

		--reset tab pages
		GarbageMan.WLselectedPage = 1
		GarbageMan.BLselectedPage = 1

		--reset selected tab
		GarbageMan.GarbageMan_Container.selectedTab = 1
		PanelTemplates_SetTab(GarbageMan.GarbageMan_Container, GarbageMan.GarbageMan_Container.selectedTab)

	elseif(event == "MERCHANT_UPDATE") then
		--call bag update functions
		GarbageMan_OnUpdate()
		GarbageMan.FilterBagsUpdate()
	elseif(event == "BANKFRAME_OPENED") then
		--raise flag for GarbageMan
		GarbageMan.isBankOpen = true --tells GarbageMan to scan more bags
	elseif(event == "BANKFRAME_CLOSED") then
		--lower flag for GarbageMan
		GarbageMan.isBankOpen = false --tells GarbageMan to scan more bags
	elseif(event == "ADDON_LOADED" and ... == "GarbageMan") then 
		--create and set interface elements
		GarbageMan.GarbageMan_AddonLoaded()
		GarbageMan.garbageButton:SetScript("Onclick", GarbageMan.SellGarbage)

		--set GarbageMan MerchantTab OnUpdate Script
		_G["MerchantFrameTab"..MerchantFrame.numTabs]:SetScript("OnUpdate", GarbageMan_OnUpdate)

		GarbageMan.eventFrame:UnregisterEvent("ADDON_LOADED")
	end
end

--Purpose: GarbageMan listens for events registered and sets event actions
--Returns: Nothing
function GarbageMan.createEvent()
	
	for _, v in ipairs(GarbageMan.EVENTS) do
		GarbageMan.eventFrame:RegisterEvent(v)
	end
	GarbageMan.eventFrame:SetScript("OnEvent", GarbageMan.EventHandler)
end

GarbageMan.createEvent()