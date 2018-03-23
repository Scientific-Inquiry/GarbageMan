GarbageMan = {
	name = "GarbageMan",
	description = "--version 7.03.05 by ScientificInquiry, |cFF42d9f4Scientific.Inquiry42@gmail.com|r\n Sells Garbage items [grey quality items]",
	BuyBackList = {},
	BankGarbageBags = {},
	WLselectedPage = 1,
	BLselectedPage = 1,
	toggleFilter = false,
	toggleFilterBank =  true,
	isBankOpen = false,
	sortedKeysWL,
	sortedKeysBL
}

GarbageMan.EVENTS = {"MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED", "ADDON_LOADED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED"}
GarbageMan.eventFrame = CreateFrame("Frame", GarbageMan.name..".EventFrame", UIParent)
GarbageMan.ScanningTooltip = CreateFrame("GameTooltip", GarbageMan.name..".ScanningTooltip", nil, "ScanningTooltipTemplate" )

SLASH_GARBAGEMAN1 = "/garbageman"
SLASH_GARBAGEMAN2 = "/gm"
SlashCmdList["GARBAGEMAN"] = function(msg, editbox)
	InterfaceOptionsFrame_OpenToCategory("GarbageMan") --Must call twice, first call opens interface.
	InterfaceOptionsFrame_OpenToCategory("GarbageMan") --Second Call opens GarbageMan options
end
