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

		--Display party members.
		--local displayedMembersLabel = false;
		local groupILevel = 0;
		local groupMembers = 0;
		for i=0, partyMembers do
			local name, level, relationship, className, areaName, comment, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetPartyResults(realIndex or self.index, i);
			--print("dbg!"..i.." of "..(partyMembers or "nil").." "..(name or "nil"));
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

	GameTooltip:AddLine("Extra info:");

	if ( areaName ) then
		GameTooltip:AddLine(format(ZONE_COLON.." %s", areaName));
	end

	-- this is sum of kills for all bosses on normal mode or flex
	if ( LFRAdvancedOptions.ShowBossKills and bossKills and bossKills > 0 ) then
		GameTooltip:AddLine(format("Boss kills: %u", bossKills));
	end

	-- max average ilvl
	if ( avgILevel and avgILevel > 0 ) then
		GameTooltip:AddLine(format(STAT_AVERAGE_ITEM_LEVEL..": %.02f", avgILevel));
	end

	-- no clue wtf this value means
	if ( gearRating and gearRating > 0 ) then
		GameTooltip:AddLine(format("Gear Rating: %u", gearRating));
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
local SearchLFGGetResults_Old = SearchLFGGetResults;
local SearchLFGGetNumResults = SearchLFGGetNumResults;
local sortOrder = false;
local idx = {};
local ilvls = {};
--local temp = {};

function MySearchLFGGetResults(index)
	local numResults, totalResults = SearchLFGGetNumResults();

	table.wipe(idx);
	table.wipe(ilvls);
	--table.wipe(temp);

	for i = 1, numResults do
		idx[i] = i;
		local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults_Old(i);
		ilvls[i] = avgILevel;
		--if not temp[i] then temp[i] = {} end
		--temp[i].name = name;
		--temp[i].level = level;
		--temp[i].areaName = areaName;
		--temp[i].className = className;
		--temp[i].comment = comment;
		--temp[i].partyMembers = partyMembers;
		--temp[i].status = status;
		--temp[i].class = class;
		--temp[i].encountersTotal = encountersTotal;
		--temp[i].encountersComplete = encountersComplete;
		--temp[i].isIneligible = isIneligible;
		--temp[i].isLeader = isLeader;
		--temp[i].isTank = isTank;
		--temp[i].isHealer = isHealer;
		--temp[i].isDamage = isDamage;
		--temp[i].bossKills = bossKills;
		--temp[i].specID = specID;
		--temp[i].isGroupLeader = isGroupLeader;
		--temp[i].armor = armor;
		--temp[i].spellDamage = spellDamage;
		--temp[i].plusHealing = plusHealing;
		--temp[i].CritMelee = CritMelee;
		--temp[i].CritRanged = CritRanged;
		--temp[i].critSpell = critSpell;
		--temp[i].mp5 = mp5;
		--temp[i].mp5Combat = mp5Combat;
		--temp[i].attackPower = attackPower;
		--temp[i].agility = agility;
		--temp[i].maxHealth = maxHealth;
		--temp[i].maxMana = maxMana;
		--temp[i].gearRating = gearRating;
		--temp[i].avgILevel = avgILevel;
		--temp[i].defenseRating = defenseRating;
		--temp[i].dodgeRating = dodgeRating;
		--temp[i].BlockRating = BlockRating;
		--temp[i].ParryRating = ParryRating;
		--temp[i].HasteRating = HasteRating;
		--temp[i].expertise = expertise;
		--temp[i].realIndex = i;
	end

	--table.sort(temp, SortByILevel);
	table.sort(idx, SortByILevel);

	local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults_Old(idx[index]);
	return name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise, idx[index];
	--local ret = temp[index];
	--for i = 1, #temp do
	--	if i ~= index then
	--		table.wipe(temp[i]);
	--	end
	--end
	--table.wipe(temp);
	--return ret.name, ret.level, ret.areaName, ret.className, ret.comment, ret.partyMembers, ret.status, ret.class, ret.encountersTotal, ret.encountersComplete, ret.isIneligible, ret.isLeader, ret.isTank, ret.isHealer, ret.isDamage, ret.bossKills, ret.specID, ret.isGroupLeader, ret.armor, ret.spellDamage, ret.plusHealing, ret.CritMelee, ret.CritRanged, ret.critSpell, ret.mp5, ret.mp5Combat, ret.attackPower, ret.agility, ret.maxHealth, ret.maxMana, ret.gearRating, ret.avgILevel, ret.defenseRating, ret.dodgeRating, ret.BlockRating, ret.ParryRating, ret.HasteRating, ret.expertise, ret.realIndex;
end

--function SortByILevel(a, b)
--	if sortOrder then
--		return a.avgILevel < b.avgILevel
--	else
--		return a.avgILevel > b.avgILevel
--	end
--end

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
		LFRBrowseFrameCopyNameButton:Enable();
	else
		LFRBrowseFrameCopyNameButton:Disable();
	end
end

LFRBrowse_UpdateButtonStates = MyLFRBrowse_UpdateButtonStates

-- Join hack
local LFRQueueFrame_Join_Old = LFRQueueFrame_Join

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
		--print(k.." "..v);
	end

	if crossRealmGroupFound and realmGroupFound then
		print("You can't list for cross realm and your realm only raids at same time. Please check your selection!");
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
