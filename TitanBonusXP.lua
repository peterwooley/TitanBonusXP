-- ******************************** Constants *******************************
-- Setup the name we want in the global namespace
TitanBonusXP = {}
-- Reduce the chance of functions and variables colliding with another addon.
local TBXP = TitanBonusXP

TBXP.id = "BonusXP";
TBXP.addon = "TitanBonusXP";
-- NOTE : The Titan convention is to name your addon toc (and folder) "Titan"<your addon>.
--        In this case TitanBonusXP.


-- These strings will be used for display. Localized strings are outside the scope of this example.
-- These strings should be localized which is outside the scope of this simple example.
TBXP.button_label = "Bonus XP: "
TBXP.menu_text = TBXP.id
TBXP.tooltip_header = TBXP.id.." Info"
TBXP.tooltip_hint_1 = "Hint: Left-click to open all bags."
TBXP.menu_option = "Options"
TBXP.menu_hide = "Hide"
TBXP.menu_show_used = "Show used slots"
TBXP.menu_show_avail = "Show available slots"

--  Get data from the TOC file.
TBXP.version = tostring(GetAddOnMetadata(TBXP.addon, "Version")) or "Unknown" 
TBXP.author = GetAddOnMetadata("TitanBonusXP", "Author") or "Unknown"
-- ******************************** Variables *******************************
-- ******************************** Functions *******************************
--[[
-- **************************************************************************
-- NAME : TitanPanelBagButton_OnLoad()
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
--]]
function TBXP.Button_OnLoad(self)
-- SDK : "registry" is the data structure Titan uses to addon info it is displaying.
--       This is the critical structure!
-- SDK : This works because the button inherits from a Titan template. In this case
--       TitanPanelComboTemplate in the XML.
-- NOTE: LDB (LibDataBroker) type addons are NOT in the scope of this example.
	self.registry = {
		id = TBXP.id,
		-- SDK : "id" MUST be unique to all the Titan specific addons
		-- Last addon loaded with same name wins...
		version = TBXP.version,
		-- SDK : "version" the version of your addon that Titan displays
		category = "Information",
		-- SDK : "category" is where the user will find your addon when right clicking
		--       on the Titan bar.
		--       Currently: General, Combat, Information, Interfacem, Profession - These may change!
		menuText = TBXP.menu_text,
		-- SDK : "menuText" is the text Titan displays when the user finds your addon by right clicking
		--       on the Titan bar.
		buttonTextFunction = "TitanBonusXP_GetButtonText", 
		-- SDK : "buttonTextFunction" is in the global name space due to the way Titan uses the routine.
		--       This routine is called to set (or update) the button text on the Titan bar.
		tooltipTitle = TBXP.tooltip_header,
		-- SDK : "tooltipTitle" will be used as the first line in the tooltip.
		tooltipTextFunction = "TitanBonusXP_GetTooltipText", 
		-- SDK : "tooltipTextFunction" is in the global name space due to the way Titan uses the routine.
		--       This routine is called to fill in the tooltip of the button on the Titan bar.
		--       It is a typical tooltip and is drawn when the cursor is over the button.
		icon = nil,
		-- SDK : "icon" needs the path to the icon to display. Blizzard uses the default extension of .tga
		--       If not needed make nil.
		--[[
		The artwork path must start with Interface\\AddOns
		Then the name of the plugin
		Then any additional folder(s) to your artwork / icons.
		--]]
		iconWidth = 16,
		-- SDK : "iconWidth" leave at 16 unless you need a smaller/larger icon
		savedVariables = {
		-- SDK : "savedVariables" are variables saved by character across logins.
		--      Get - TitanGetVar (id, name)
		--      Set - TitanSetVar (id, name, value)
			-- SDK : The 2 variables below are for our example
			-- SDK : Titan will handle the 3 variables below but the addon code must put it on the menu
			ShowLabelText = 1,
		}
	};     

	-- Tell Blizzard the events we need
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	-- Any other addon specific "on load" code here
	
	-- shamelessly print a load message to chat window
	DEFAULT_CHAT_FRAME:AddMessage(
		GREEN_FONT_COLOR_CODE
		..TBXP.addon..TBXP.id.." "..TBXP.version
		.." by "
		..FONT_COLOR_CODE_CLOSE
		.."|cFFFFFF00"..TBXP.author..FONT_COLOR_CODE_CLOSE);
end
--[[
-- **************************************************************************
-- NAME : TBXP.Button_OnEvent()
-- DESC : Parse events registered to plugin and act on them
-- USE  : _OnEvent handler from the XML file
-- **************************************************************************
--]]
function TBXP.Button_OnEvent(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		-- do any set up needed          
		self:RegisterEvent("BAG_UPDATE");          
	end
end

--[[
-- **************************************************************************
-- NAME : TBXP.Button_OnClick(button)
-- DESC : Opens all bags on a LeftClick
-- VARS : button = value of action
-- USE  : _OnClick handler from the XML file
-- **************************************************************************
--]]
function TBXP.Button_OnClick(self, button)
	if (button == "LeftButton") then
		ToggleAllBags();
	end
end
--[[
-- **************************************************************************
-- NAME : TitanBonusXP_GetButtonText(id)
-- DESC : Calculate bag space logic then display data on button
-- VARS : id = button ID
-- **************************************************************************
--]]
function TitanBonusXP_GetButtonText(id)
-- SDK : As specified in "registry"
--       Any button text to set or update goes here
	local button, id = TitanUtils_GetButton(id, true);
	-- SDK : "TitanUtils_GetButton" is used to get a reference to the button Titan created.
	--       The reference is not needed by this example.

	return TBXP.button_label, GetBonusXP();
end
--[[
-- **************************************************************************
-- NAME : TitanBonusXP_GetTooltipText()
-- DESC : Display tooltip text
-- **************************************************************************
--]]
function TitanBonusXP_GetTooltipText()
-- SDK : As specified in "registry"
--       Create the tooltip text here
	local str = "slots"
	if (TitanGetVar(TBXP.id, "ShowUsedSlots")) then
		str = " used "..str
	else
		str = " available "..str
	end
	return TBXP.GetBagSlotInfo()
		..str.."\n"
		..TitanUtils_GetGreenText(TBXP.tooltip_hint_1);
	-- This is just a simple example.
end
--[[
-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareBagMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
--]]
function TitanPanelRightClickMenu_PrepareBonusXPMenu()
-- SDK : This is a routine that Titan 'assumes' will exist. The name is a specific format
--       "TitanPanelRightClickMenu_Prepare"..ID.."Menu"
--       where ID is the "id" from "registry"
	local info
--[[ NOTE :
Titan does not use the Blizzard UI drop down menu because it can cause taint issues. 
Instead it uses a custom library provided by arith. It uses the Blizzard routines but
in a taint safe way. The library uses the same names prefixed by "L_" and a drop down creation routine.
The Titan main code will create the drop down menu but the plugin must fill in any buttons it
wants to display. The buttons will be in the same order as they are added (L_UIDropDownMenu_AddButton).
For 'tiered' menus, two things must occur:
1) The button to 'pop' the next level must be created with attribute "hasArrow" as 1 / true and given an appropriate (localized) text label
2)The level of the menu must be checked (L_UIDROPDOWNMENU_MENU_LEVEL). Within the check ensure the cursor is over the 
button (if L_UIDROPDOWNMENU_MENU_VALUE == "Options", where "Options" is the developer assigned .value)
Then add additional buttons as desired.
For this example plugin, we show the standard Titan buttons plus options to determine what numbers to display.
--]]
-- menu creation is beyond the scope of this example
-- but note the Titan get / set routines and other Titan routines being used.
-- SDK : "TitanPanelRightClickMenu_AddTitle" is used to place the title in the (sub)menu

	-- level 2 menu
	if L_UIDROPDOWNMENU_MENU_LEVEL == 2 then
		if L_UIDROPDOWNMENU_MENU_VALUE == "Options" then
			TitanPanelRightClickMenu_AddTitle(TBXP.menu_option, L_UIDROPDOWNMENU_MENU_LEVEL)
			info = {};
			info.text = TBXP.menu_show_used;
			info.func = TitanPanelBagButton_ShowUsedSlots;
			info.checked = TitanGetVar(TBXP.id, "ShowUsedSlots");
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);

			info = {};
			info.text = TBXP.menu_show_avail;
			info.func = TitanPanelBagButton_ShowAvailableSlots;
			info.checked = TitanUtils_Toggle(TitanGetVar(TBXP.id, "ShowUsedSlots"));
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		end
		return -- so the menu does not create extra repeat buttons
	end
	
	-- level 1 menu
	if L_UIDROPDOWNMENU_MENU_LEVEL == 1 then
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TBXP.id].menuText);
		-- SDK : "TitanPanelRightClickMenu_AddSpacer" is used to put a blank line in the menu
		--TitanPanelRightClickMenu_AddToggleIcon(TBXP.id);
		-- SDK : "TitanPanelRightClickMenu_AddToggleIcon" is used to put a "Show icon" (localized) in the menu.
		--        registry.savedVariables.ShowIcon
		TitanPanelRightClickMenu_AddToggleLabelText(TBXP.id);
		-- SDK : "TitanPanelRightClickMenu_AddToggleLabelText" is used to put a "Show label text" (localized) in the menu.
		--        registry.savedVariables.ShowLabelText
		TitanPanelRightClickMenu_AddSpacer();     
		TitanPanelRightClickMenu_AddCommand(TBXP.menu_hide, TBXP.id, TITAN_PANEL_MENU_FUNC_HIDE);
		-- SDK : The routine above is used to put a "Hide" (localized) in the menu.
	end

end
--[[
-- **************************************************************************
-- NAME : TitanPanelBagButton_ShowUsedSlots()
-- DESC : Set option to show used slots
-- **************************************************************************
--]]
function TitanPanelBagButton_ShowUsedSlots()
	TitanSetVar(TBXP.id, "ShowUsedSlots", 1);
	TitanPanelButton_UpdateButton(TBXP.id);
end
--[[
-- **************************************************************************
-- NAME : TitanPanelBagButton_ShowAvailableSlots()
-- DESC : Set option to show available slots
-- **************************************************************************
--]]
function TitanPanelBagButton_ShowAvailableSlots()
	TitanSetVar(TBXP.id, "ShowUsedSlots", nil);
	TitanPanelButton_UpdateButton(TBXP.id);
end
--[[
-- **************************************************************************
-- NAME : TitanBonusXP_GetButtonText(id)
-- DESC : Calculate bag space using what the user wants to see
-- VARS : 
-- **************************************************************************
--]]
function TBXP.GetBagSlotInfo()
-- SDK : As specified in "registry"
--       Any button text to set or update goes here
	local totalSlots, usedSlots, availableSlots;

	totalSlots = 0;
	usedSlots = 0;
	for bag = 0, 4 do
		local size = GetContainerNumSlots(bag);
		if (size and size > 0) then
			totalSlots = totalSlots + size;
			for slot = 1, size do
				if (GetContainerItemInfo(bag, slot)) then
					usedSlots = usedSlots + 1;
				end
			end
		end
	end
	availableSlots = totalSlots - usedSlots;

	local bagText, bagRichText
     
  bagRichText = TitanUtils_GetColoredText(bagText, NORMAL_FONT_COLOR);

	return bagRichText
end
