-- Tab hack
local LFRFrame_SetActiveTab_Old = LFRFrame_SetActiveTab

function MyLFRFrame_SetActiveTab(tab)
	LFRFrame_SetActiveTab_Old(tab)

	if tab == 1 then
		RaidBrowserFrame:SetSize(350, 450);
	else
		RaidBrowserFrame:SetSize(400, 450);
	end
end

LFRFrame_SetActiveTab = MyLFRFrame_SetActiveTab

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
	local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise, fakeIndex = SearchLFGGetResults(self.index);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 47, -37);

	if ( partyMembers > 0 ) then
		GameTooltip:AddLine(LOOKING_FOR_RAID);

		GameTooltip:AddLine(name);
		GameTooltip:AddLine(GetPlayerInfoString(level, specID, className));
		GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0, 0.25, 0, 1);

		GameTooltip:AddLine(format(LFM_NUM_RAID_MEMBER_TEMPLATE, partyMembers));
		-- Bogus texture to fix spacing
		GameTooltip:AddTexture("");

		--Display party members.
		local displayedMembersLabel = false;
		for i=1, partyMembers do
			local name, level, relationship, className, areaName, comment, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetPartyResults(fakeIndex or self.index, i);
			if ( relationship ) then
				if ( not displayedMembersLabel ) then
					displayedMembersLabel = true;
					GameTooltip:AddLine("\n"..IMPORTANT_PEOPLE_IN_GROUP);
				end
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

	if ( encountersComplete > 0 or isIneligible ) then
		GameTooltip:AddLine("\n"..BOSSES);
		for i=1, encountersTotal do
			local bossName, texture, isKilled, isIneligible = SearchLFGGetEncounterResults(self.index, i);
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

	GameTooltip:AddLine("Extra info:");

	if ( areaName ) then
		GameTooltip:AddLine(format(ZONE_COLON.." %s", areaName));
	end

	-- this is sum of kills for all bosses on normal mode
	if ( bossKills and bossKills > 0 ) then
		GameTooltip:AddLine(format("Boss kills (normal): %u", bossKills));
	end

	-- always true?
--	if ( isGroupLeader ) then
--		GameTooltip:AddLine(format("Is Group Leader: %s", tostring(isGroupLeader)));
--	end

	if ( armor and armor > 0 ) then
		GameTooltip:AddLine(format(ARMOR_TEMPLATE, armor));
	end

	if ( (spellDamage and spellDamage > 0) or (plusHealing and plusHealing > 0) ) then
		GameTooltip:AddLine(format(STAT_SPELLPOWER..": %u (%u +heal)", spellDamage, plusHealing));
	end

	if ( (CritMelee and CritMelee > 0) or (CritRanged and CritRanged > 0) or (critSpell and critSpell > 0) ) then
		GameTooltip:AddLine(format(MELEE_CRIT_CHANCE..": melee %u, ranged %u, spell %u", CritMelee, CritRanged, critSpell));
	end

	if ( (mp5 and mp5 > 0) or (mp5Combat and mp5Combat > 0) ) then
		GameTooltip:AddLine(format("MP5: %u (in combat %u)", mp5, mp5Combat));
	end

	if ( attackPower and attackPower > 0 ) then
		GameTooltip:AddLine(format(MELEE_ATTACK_POWER..": %u", attackPower));
	end

	if ( agility and agility > 0 ) then
		GameTooltip:AddLine(format(AGILITY_COLON.." %u", agility));
	end

	if ( maxHealth and maxHealth > 0 ) then
		GameTooltip:AddLine(format(MAX_HP_TEMPLATE, maxHealth));
	end

	if ( maxMana and maxMana > 0 ) then
		GameTooltip:AddLine(format(MANA_COLON.." %u", maxMana));
	end

	-- no clue wtf this value means
	if ( gearRating and gearRating > 0 ) then
		GameTooltip:AddLine(format("Gear Rating: %u", gearRating));
	end

	-- max average ilvl
	if ( avgILevel and avgILevel > 0 ) then
		GameTooltip:AddLine(format(STAT_AVERAGE_ITEM_LEVEL..": %.02f", avgILevel));
	end

	-- has been removed in Cataclysm as stat
	if ( defenseRating and defenseRating > 0 ) then
		GameTooltip:AddLine(format("Defense Rating: %u", defenseRating));
	end

	if ( dodgeRating and dodgeRating > 0 ) then
		GameTooltip:AddLine(format(STAT_DODGE..": %u", dodgeRating));
	end

	if ( BlockRating and BlockRating > 0 ) then
		GameTooltip:AddLine(format(SHIELD_BLOCK_TEMPLATE, BlockRating));
	end

	if ( ParryRating and ParryRating > 0 ) then
		GameTooltip:AddLine(format(STAT_PARRY..": %u", ParryRating));
	end

	if ( HasteRating and HasteRating > 0 ) then
		GameTooltip:AddLine(format(STAT_HASTE..": %u", HasteRating));
	end

	if ( expertise and expertise > 0 ) then
		GameTooltip:AddLine(format(STAT_EXPERTISE..": %.02f", expertise).."%");
	end

	GameTooltip:Show();
end

for i=1, NUM_LFR_LIST_BUTTONS do
	local button = _G["LFRBrowseFrameListButton"..i];
	button:SetScript("OnEnter", MyLFRBrowseButton_OnEnter);
	button:SetSize(360, 16);
	local tex = button:GetHighlightTexture()
	tex:SetSize(360, 16);

	local fs = button:CreateFontString("LFRBrowseFrameListButton"..i.."ILevel", "ARTWORK", "GameFontHighlightSmall")
	fs:SetSize(50, 14);
	fs:SetPoint("LEFT", "LFRBrowseFrameListButton"..i.."PartyIcon", "RIGHT", 9, 0);
	button.ilvl = fs;
end

-- ilevel sort hack (breaks for group leaders, disabled)
local SearchLFGGetResults_Old = SearchLFGGetResults;
local sortOrder = false;
local ilevelSortEnabled = false;

function MySearchLFGGetResults(index)
	local numResults, totalResults = SearchLFGGetNumResults();
	local values = {};

	for i = 1, numResults do
		values[i] = {SearchLFGGetResults_Old(i)};
		table.insert(values[i], i); -- put original index
	end

	table.sort(values, SortByILevel);
	return unpack(values[index]);
end

function SortByILevel(a, b)
	if sortOrder then
		return a[32] < b[32]
	else
		return a[32] > b[32]
	end
end

function MySearchLFGSort(self)
	if ilevelSortEnabled then
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
	else
		if ( self.sortType and self.sortType ~= "ilevel") then
			SearchLFGSort(self.sortType);
		end
	end
	PlaySound("igMainMenuOptionCheckBoxOn");
end

for i = 1, 7 do
	_G["LFRBrowseFrameColumnHeader"..i]:SetScript("OnClick", MySearchLFGSort);
end

-- Scroll Bar Fix
LFRBrowseFrameListScrollFrame:SetPoint("TOPRIGHT", -31, 0)
LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", 0, 29)

-- SetDungeon hack
local LFRQueueFrameSpecificListButton_SetDungeon_Old = LFRQueueFrameSpecificListButton_SetDungeon

function MyLFRQueueFrameSpecificListButton_SetDungeon(button, dungeonID, mode, submode)
	LFRQueueFrameSpecificListButton_SetDungeon_Old(button, dungeonID, mode, submode)
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
		
	LFGQueueFrame_UpdateLFGDungeonList(LFRRaidList, LFRHiddenByCollapseList, checkedList, MyLFGList_FilterFunction, LFR_MAX_SHOWN_LEVEL_DIFF);
	
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
		PVEFrameCopyNameButton:Enable();
	else
		PVEFrameCopyNameButton:Disable();
	end
end

LFRBrowse_UpdateButtonStates = MyLFRBrowse_UpdateButtonStates
