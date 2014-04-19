local SearchLFGGetResults_Old = SearchLFGGetResults;
local SearchLFGGetNumResults = SearchLFGGetNumResults;
local classFilter = "NONE";

local function Colorize(value)
	--if something111 then
	--	return "|cffffffff"..value.."|r"
	--end
	--return value
	return "|cffffffff"..value.."|r"
end

local function round(number, decimals)
	return (("%%.%df"):format(decimals)):format(number)
end

-- Tab hack
local LFRFrame_SetActiveTab_Old = LFRFrame_SetActiveTab

function MyLFRFrame_SetActiveTab(tab)
	LFRFrame_SetActiveTab_Old(tab)

	if tab == 1 then
		RaidBrowserFrame:SetSize(350, 450);
	else
		RaidBrowserFrame:SetSize(420, 450);
	end
end

LFRFrame_SetActiveTab = MyLFRFrame_SetActiveTab

-- Update hack
local LFRBrowseFrameList_Update_Old = LFRBrowseFrameList_Update

function MyLFRBrowseFrameList_Update()
	LFRBrowseFrameRefreshButton.timeUntilNextRefresh = LFR_BROWSE_AUTO_REFRESH_TIME;

	local numResults, totalResults = SearchLFGGetNumResults();
	local filteredNum = 0;
	local foundIds = {};
	for i = 1, numResults do
		local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults_Old(i);
		if classFilter == "NONE" or classFilter == class then
			filteredNum = filteredNum + 1;
			table.insert(foundIds, i);
		end
	end

	FauxScrollFrame_Update(LFRBrowseFrameListScrollFrame, filteredNum, NUM_LFR_LIST_BUTTONS, 16);

	local offset = FauxScrollFrame_GetOffset(LFRBrowseFrameListScrollFrame);

	for i=1, NUM_LFR_LIST_BUTTONS do
		local button = _G["LFRBrowseFrameListButton"..i];

		if ( i <= filteredNum ) then
			LFRBrowseFrameListButton_SetData(button, foundIds[i + offset]);
			button:Show();
		else
			button:Hide();
		end
	end

	if ( LFRBrowseFrame.selectedName ) then
		local nameStillThere = false;
		for i=1, numResults do
			local name = SearchLFGGetResults(i);
			if ( LFRBrowseFrame.selectedName == name ) then
				nameStillThere = true;
				break;
			end
		end
		if ( not nameStillThere ) then
			LFRBrowseFrame.selectedName = nil;
		end
	end

	LFRBrowse_UpdateButtonStates();
end

LFRBrowseFrameList_Update = MyLFRBrowseFrameList_Update

-- SetData hack
local LFRBrowseFrameListButton_SetData_Old = LFRBrowseFrameListButton_SetData;

function MyLFRBrowseFrameListButton_SetData(button, index)
	LFRBrowseFrameListButton_SetData_Old(button, index);

	local ilvl = select(32, SearchLFGGetResults(index)) or 0;
	button.ilvl:SetText(format("%.02f", ilvl));
end

LFRBrowseFrameListButton_SetData = MyLFRBrowseFrameListButton_SetData

-- OnEnter hack
function MyLFRBrowseButton_OnEnter(self)
	LFRAdvanced.lastOnEnterButton = self;
	local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise, realIndex = SearchLFGGetResults(self.index);
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 50, 16);

	if ( partyMembers > 0 ) then
		GameTooltip:AddLine(LOOKING_FOR_RAID);

		GameTooltip:AddLine(name);
		GameTooltip:AddLine(GetPlayerInfoString(level, specID, className));
		GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0, 0.25, 0, 1);

		GameTooltip:AddLine("\n"..format(LFM_NUM_RAID_MEMBER_TEMPLATE, partyMembers + 1));
		-- Bogus texture to fix spacing
		--GameTooltip:AddTexture("");

		if ( LFRAdvancedOptions.ShowPartyInfo ) then
			--Display party members.
			--local displayedMembersLabel = false;
			local groupILevel = 0;
			local groupMembers = 0;
			for i=0, partyMembers do
				local name, level, relationship, className, areaName, comment, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetPartyResults(realIndex or self.index, i);
				if name then
					groupILevel = groupILevel + avgILevel;
					groupMembers = groupMembers + 1

					--if ( not displayedMembersLabel ) then
					--	displayedMembersLabel = true;
					--	GameTooltip:AddLine("\n"..IMPORTANT_PEOPLE_IN_GROUP);
					--end

					if groupMembers < 20 then--limit to 20 members in tooltip
						if ( relationship ) then
							if ( relationship == "ignored" ) then
								GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILevel, RED_FONT_COLOR_CODE), IGNORED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
							elseif ( relationship == "friend" ) then
								GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILevel, GREEN_FONT_COLOR_CODE), FRIEND, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
							end
						else
							if IsGuildie(name) then
								GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILevel, GREEN_FONT_COLOR_CODE), GUILD, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
							else
								GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILevel, NORMAL_FONT_COLOR_CODE), PLAYER, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
							end
						end
					end
				end
			end
			if groupILevel > 0 then
				GameTooltip:AddLine(format("Group avg ilvl: %.02f", groupILevel/groupMembers));
			end
		end
	else
		GameTooltip:AddLine(name);
		GameTooltip:AddLine(GetPlayerInfoString(level, specID, className));
	end

	if ( comment and comment ~= "" ) then
		GameTooltip:AddLine("\n"..comment, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
	end

	if ( partyMembers == 0 ) then
		GameTooltip:AddLine("\n"..LFG_TOOLTIP_ROLES);
		if ( isTank ) then
			GameTooltip:AddLine(TANK);
			GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.5, 0.75, 0, 1);
		end
		if ( isHealer ) then
			GameTooltip:AddLine(HEALER);
			GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.75, 1, 0, 1);
		end
		if ( isDamage ) then
			GameTooltip:AddLine(DAMAGER);
			GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.25, 0.5, 0, 1);
		end
	end

	if ( LFRAdvancedOptions.ShowLockouts ) then
		if ( encountersComplete > 0 or isIneligible ) then
			GameTooltip:AddLine("\n"..BOSSES);
			for i=1, encountersTotal do
				local bossName, texture, isKilled, isIneligible = SearchLFGGetEncounterResults(realIndex or self.index, i);
				if ( isKilled ) then
					GameTooltip:AddDoubleLine(bossName, BOSS_DEAD, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
				elseif ( isIneligible ) then
					GameTooltip:AddDoubleLine(bossName, BOSS_ALIVE_INELIGIBLE, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
				else
					GameTooltip:AddDoubleLine(bossName, BOSS_ALIVE, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
				end
			end
		elseif ( partyMembers > 0 and encountersTotal > 0) then
			GameTooltip:AddLine("\n"..ALL_BOSSES_ALIVE);
		end
	end

	GameTooltip:AddLine("• Extra info •");

	if ( areaName ) then
		GameTooltip:AddLine(format(ZONE_COLON.." %s", Colorize(areaName)));
	end

	-- this is sum of kills for all bosses on normal mode or flex
	if ( LFRAdvancedOptions.ShowBossKills and bossKills and bossKills > 0 ) then
		GameTooltip:AddLine(format("Boss kills: %s", Colorize(bossKills)));
	end

	-- max average ilvl
	if ( avgILevel and avgILevel > 0 ) then
		GameTooltip:AddLine(format(STAT_AVERAGE_ITEM_LEVEL..": %s", Colorize(round(avgILevel, 2))));
	end

	-- no clue wtf this value means
	if ( gearRating and gearRating > 0 ) then
		GameTooltip:AddLine(format("Gear Rating: %s", Colorize(gearRating)));
	end

	-- always true?
--	if ( isGroupLeader ) then
--		GameTooltip:AddLine(format("Is Group Leader: %s", tostring(isGroupLeader)));
--	end

	if not LFRAdvancedOptions.ShowStats and not IsShiftKeyDown() then
		GameTooltip:Show();
		return;
	end

	if ( armor and armor > 0 ) then
		GameTooltip:AddLine(format(ARMOR_TEMPLATE, Colorize(armor)));
	end

	if ( (spellDamage and spellDamage > 0) or (plusHealing and plusHealing > 0) ) then
		GameTooltip:AddLine(format(STAT_SPELLPOWER..": %s (%s +heal)", Colorize(spellDamage), Colorize(plusHealing)));
	end

	if ( (CritMelee and CritMelee > 0) or (CritRanged and CritRanged > 0) or (critSpell and critSpell > 0) ) then
		GameTooltip:AddLine(format(MELEE_CRIT_CHANCE..": melee %s, ranged %s, spell %s", Colorize(CritMelee), Colorize(CritRanged), Colorize(critSpell)));
	end

	if ( (mp5 and mp5 > 0) or (mp5Combat and mp5Combat > 0) ) then
		GameTooltip:AddLine(format("MP5: %s (in combat %s)", Colorize(mp5), Colorize(mp5Combat)));
	end

	if ( attackPower and attackPower > 0 ) then
		GameTooltip:AddLine(format(MELEE_ATTACK_POWER..": %s", Colorize(attackPower)));
	end

	if ( agility and agility > 0 ) then
		GameTooltip:AddLine(format(AGILITY_COLON.." %s", Colorize(agility)));
	end

	if ( maxHealth and maxHealth > 0 ) then
		GameTooltip:AddLine(format(HEALTH_COLON.." %s", Colorize(maxHealth)));
	end

	if ( maxMana and maxMana > 0 ) then
		GameTooltip:AddLine(format(MANA_COLON.." %s", Colorize(maxMana)));
	end

	-- has been removed in Cataclysm as stat
	if ( defenseRating and defenseRating > 0 ) then
		GameTooltip:AddLine(format("Defense Rating: %s", Colorize(defenseRating)));
	end

	if ( dodgeRating and dodgeRating > 0 ) then
		GameTooltip:AddLine(format(STAT_DODGE..": %s", Colorize(dodgeRating)));
	end

	if ( BlockRating and BlockRating > 0 ) then
		GameTooltip:AddLine(format(SHIELD_BLOCK_TEMPLATE, Colorize(BlockRating)));
	end

	if ( ParryRating and ParryRating > 0 ) then
		GameTooltip:AddLine(format(STAT_PARRY..": %s", Colorize(ParryRating)));
	end

	if ( HasteRating and HasteRating > 0 ) then
		GameTooltip:AddLine(format(STAT_HASTE..": %s", Colorize(HasteRating)));
	end

	if ( expertise and expertise > 0 ) then
		GameTooltip:AddLine(format(STAT_EXPERTISE..": %s", Colorize(round(expertise, 2).."%")));
	end

	GameTooltip:Show();
end

function MyLFRBrowseButton_OnLeave(self)
	GameTooltip:Hide();
	LFRAdvanced.lastOnEnterButton = nil;
end

for i=1, NUM_LFR_LIST_BUTTONS do
	local button = _G["LFRBrowseFrameListButton"..i];
	button:SetScript("OnEnter", MyLFRBrowseButton_OnEnter);
	button:SetScript("OnLeave", MyLFRBrowseButton_OnLeave);
	button:SetSize(375, 16);
	button.level:SetSize(30, 14)
	local tex = button:GetHighlightTexture()
	tex:SetSize(375, 16);

	local fs = button:CreateFontString("LFRBrowseFrameListButton"..i.."ILevel", "ARTWORK", "GameFontHighlightSmall")
	fs:SetSize(50, 14);
	fs:SetPoint("LEFT", "LFRBrowseFrameListButton"..i.."PartyIcon", "RIGHT", 0, 0);
	button.ilvl = fs;
end

-- ilevel sort hack, slow
local sortOrder = false;
local idx = {};
local ilvls = {};

function MySearchLFGGetResults(index)
	local numResults, totalResults = SearchLFGGetNumResults();

	table.wipe(idx);
	table.wipe(ilvls);

	for i = 1, numResults do
		idx[i] = i;
		local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults_Old(i);
		ilvls[i] = avgILevel;
	end

	table.sort(idx, SortByILevel);

	local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults_Old(idx[index]);
	return name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise, idx[index];
end

function SortByILevel(a, b)
	if sortOrder then
		return ilvls[a] < ilvls[b]
	else
		return ilvls[a] > ilvls[b]
	end
end

function MySearchLFGSort(self)
	if ( self.sortType == "ilevel" ) then
		sortOrder = not sortOrder;
		SearchLFGGetResults = MySearchLFGGetResults
		if ( LFRBrowseFrame:IsVisible() ) then
			LFRBrowseFrameList_Update();
		end
	else
		SearchLFGGetResults = SearchLFGGetResults_Old
		if ( self.sortType ) then
			SearchLFGSort(self.sortType);
		end
	end
	PlaySound("igMainMenuOptionCheckBoxOn");
end

for i = 1, 7 do
	_G["LFRBrowseFrameColumnHeader"..i]:SetScript("OnClick", MySearchLFGSort);
end

-- Scroll Bar Fix
LFRBrowseFrameListScrollFrame:SetPoint("TOPRIGHT", -31, 0);
LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", 0, 29);

LFRBrowseFrameRaidDropDown:SetPoint("TOPLEFT", 60, -25);

function LFRBrowseFrameClassDropDown_SetUp(self)
	UIDropDownMenu_SetWidth(self, 50);
	UIDropDownMenu_Initialize(self, LFRBrowseFrameClassDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(LFRBrowseFrameClassDropDown, classFilter);
end

function LFRBrowseFrameClassDropDown_Initialize(self, level)
	local info = UIDropDownMenu_CreateInfo();

	if ( not level or level == 1 ) then
		info.text = NONE;
		info.value = "NONE";
		info.func = LFRBrowseFrameClassDropDownButton_OnClick;
		info.checked = classFilter == info.value;
		UIDropDownMenu_AddButton(info);

		for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			info.text = v;
			info.value = k;
			info.func = LFRBrowseFrameClassDropDownButton_OnClick;
			info.checked = classFilter == info.value;
			UIDropDownMenu_AddButton(info, 1);
		end
	end
end

function LFRBrowseFrameClassDropDownButton_OnClick(self)
	LFRBrowseFrameClassDropDown.activeValue = self.value;
	UIDropDownMenu_SetSelectedValue(LFRBrowseFrameClassDropDown, self.value);
	HideDropDownMenu(1);	--Hide the category menu. It gets annoying.
	classFilter = self.value;
	LFRBrowseFrameList_Update();
end

-- SetDungeon hack
local LFRQueueFrameSpecificListButton_SetDungeon_Old = LFRQueueFrameSpecificListButton_SetDungeon

function MyLFRQueueFrameSpecificListButton_SetDungeon(button, dungeonID, mode, submode)
	LFRQueueFrameSpecificListButton_SetDungeon_Old(button, dungeonID, mode, submode)

	if LFRAdvancedOptions.ShowOldRaids then
		-- unlock it!
		if ( LFR_CanQueueForMultiple() ) then
			button.enableButton:Show();
			LFGSpecificChoiceEnableButton_SetIsRadio(button.enableButton, false);
		else
			if ( LFGIsIDHeader(dungeonID) ) then
				button.enableButton:Hide();
			else
				button.enableButton:Show();
				LFGSpecificChoiceEnableButton_SetIsRadio(button.enableButton, true);
			end
		end
		button.lockedIndicator:Hide();
	end
end

LFRQueueFrameSpecificListButton_SetDungeon = MyLFRQueueFrameSpecificListButton_SetDungeon

-- Update hack
function MyLFRQueueFrame_Update()
	local mode, submode = GetLFGMode(LE_LFG_CATEGORY_LFR);

	local checkedList;
	if ( RaidBrowser_IsEmpowered() and mode ~= "listed") then
		checkedList = LFGEnabledList;
	else
		checkedList = LFGQueuedForList[LE_LFG_CATEGORY_LFR];
	end

	LFRRaidList = GetLFRChoiceOrder(LFRRaidList);

	if LFRAdvancedOptions.ShowOldRaids then
		LFGQueueFrame_UpdateLFGDungeonList(LFRRaidList, LFRHiddenByCollapseList, checkedList, MyLFGList_FilterFunction, LFR_MAX_SHOWN_LEVEL_DIFF);
	else
		LFGQueueFrame_UpdateLFGDungeonList(LFRRaidList, LFRHiddenByCollapseList, checkedList, LFR_CURRENT_FILTER, LFR_MAX_SHOWN_LEVEL_DIFF);
	end

	LFRQueueFrameSpecificList_Update();
end

LFRQueueFrame_Update = MyLFRQueueFrame_Update

-- UpdateButtonStates hack
local LFRBrowse_UpdateButtonStates_Old = LFRBrowse_UpdateButtonStates

function MyLFRBrowse_UpdateButtonStates()
	LFRBrowse_UpdateButtonStates_Old()
	local playerName = UnitName("player");
	local selectedName = LFRBrowseFrame.selectedName;

	if ( selectedName and selectedName ~= playerName ) then
		LFRBrowseFrameCopyNameButton:Enable();
	else
		LFRBrowseFrameCopyNameButton:Disable();
	end
end

LFRBrowse_UpdateButtonStates = MyLFRBrowse_UpdateButtonStates

-- Join hack
local LFRQueueFrame_Join_Old = LFRQueueFrame_Join
local listErrorMsg = "You can't list for cross realm and your realm only raids at same time.\nPlease check your selection!";

function MyLFRQueueFrame_Join()
	local ids = {}
	for _, queueID in pairs(LFRRaidList) do
		if not LFGIsIDHeader(queueID) and LFGEnabledList[queueID] then
			local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, repAmount, forceHide = GetLFGDungeonInfo(queueID);
			if typeID == 2 then
				ids[queueID] = groupID;
			end
		end
	end
	for _, queueID in pairs(LFRHiddenByCollapseList) do
		if not LFGIsIDHeader(queueID) and LFGEnabledList[queueID] then
			local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, repAmount, forceHide = GetLFGDungeonInfo(queueID);
			if typeID == 2 then
				ids[queueID] = groupID;
			end
		end
	end

	local crossRealmGroupFound = false;
	local realmGroupFound = false;
	for k, v in pairs(ids) do
		if v == -45 or v == -46 then
			crossRealmGroupFound = true;
		else
			realmGroupFound = true;
		end
	end

	if crossRealmGroupFound and realmGroupFound then
		UIErrorsFrame:AddMessage(listErrorMsg, 1.0, 0.1, 0.1, 1.0);
		print(listErrorMsg);
		print("You have selected:");

		for k, v in pairs(ids) do
			local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, repAmount, forceHide = GetLFGDungeonInfo(k);
			if v == -45 or v == -46 then
				print(name.."-"..(GetDifficultyInfo(difficulty) or "Unknown difficulty").." (Cross realm)");
			else
				print(name.."-"..(GetDifficultyInfo(difficulty) or "Unknown difficulty").." (Your realm only)");
			end
		end
		return;
	end

	LFRQueueFrame_Join_Old();
end

LFRQueueFrame_Join = MyLFRQueueFrame_Join
