NAME_ILVL_TEMPLATE = "|c%s%s %s (%.02f)|r";

local function IsGuildie(player)
    local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
    for i = 1, totalMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i);
        if name == player then
            return true
        end
    end
    return false
end

function MyFunction(self, ...)
    local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, CritSpell, MP5, MP5Combat, AttackPower, Agility, Health, Mana, gearRating, avgILVL, defenseRating, Dodge, Block, Parry, Haste, Expertise = SearchLFGGetResults(self.index);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 47, -37);

    if ( partyMembers > 0 ) then
        GameTooltip:AddLine(LOOKING_FOR_RAID);

        GameTooltip:AddLine(name);
        GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0, 0.25, 0, 1);

        GameTooltip:AddLine(format(LFM_NUM_RAID_MEMBER_TEMPLATE, partyMembers));
        -- Bogus texture to fix spacing
        GameTooltip:AddTexture("");

        --Display party members.
        local displayedMembersLabel = false;
        for i=1, partyMembers do
            -- SearchLFGGetPartyResults also returns "isLeader ... Expertise" fields as SearchLFGGetResults does
            local name, level, relationship, className, areaName, comment, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, CritSpell, MP5, MP5Combat, AttackPower, Agility, Health, Mana, gearRating, avgILVL, defenseRating, Dodge, Block, Parry, Haste, Expertise = SearchLFGGetPartyResults(self.index, i);
            if ( relationship ) then
                if ( not displayedMembersLabel ) then
                    displayedMembersLabel = true;
                    GameTooltip:AddLine("\n"..IMPORTANT_PEOPLE_IN_GROUP);
                end
                if ( relationship == "ignored" ) then
                    GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILVL, RED_FONT_COLOR), IGNORED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
                elseif ( relationship == "friend" ) then
                    GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILVL, GREEN_FONT_COLOR), FRIEND, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                end
            else
                if IsGuildie(name) then
                    GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILVL, GREEN_FONT_COLOR), FRIEND, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                else
                    GameTooltip:AddDoubleLine(GetPlayerInfoStringWithIlvl(name, level, specID, className, avgILVL, NORMAL_FONT_COLOR), PLAYER, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
                end
            end
        end
    else
        GameTooltip:AddLine(name);
        GameTooltip:AddLine(format(FRIENDS_LEVEL_TEMPLATE, level, className));
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

    if ( encountersComplete > 0 ) then
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

    GameTooltip:AddLine(GetPlayerInfoString(level, class, specID, className));

    GameTooltip:AddLine("Extra info:");

    if ( areaName ) then
        GameTooltip:AddLine(format(ZONE_COLON.." %s", areaName));
    end

    if ( bossKills and bossKills > 0 ) then
        GameTooltip:AddLine(format("Boss kills: %u", bossKills));
    end

    if ( isGroupLeader ) then
        GameTooltip:AddLine(format("Is Group Leader: %s", tostring(isGroupLeader)));
    end

    if ( armor and armor > 0 ) then
        GameTooltip:AddLine(format(ARMOR_TEMPLATE, armor));
    end

    if ( (spellDamage and spellDamage > 0) or (plusHealing and plusHealing > 0) ) then
        GameTooltip:AddLine(format(STAT_SPELLPOWER..": %u (%u +heal)", spellDamage, plusHealing));
    end

    if ( (CritMelee and CritMelee > 0) or (CritRanged and CritRanged > 0) or (CritSpell and CritSpell > 0) ) then
        GameTooltip:AddLine(format(MELEE_CRIT_CHANCE..": melee %u, ranged %u, spell %u", CritMelee, CritRanged, CritSpell));
    end

    if ( (MP5 and MP5 > 0) or (MP5Combat and MP5Combat > 0) ) then
        GameTooltip:AddLine(format("MP5: %u (in combat %u)", MP5, MP5Combat));
    end

    if ( AttackPower and AttackPower > 0 ) then
        GameTooltip:AddLine(format(MELEE_ATTACK_POWER..": %u", AttackPower));
    end

    if ( Agility and Agility > 0 ) then
        GameTooltip:AddLine(format(AGILITY_COLON.." %u", Agility));
    end

    if ( Health and Health > 0 ) then
        GameTooltip:AddLine(format(MAX_HP_TEMPLATE, Health));
    end

    if ( Mana and Mana > 0 ) then
        GameTooltip:AddLine(format(MANA_COLON.." %u", Mana));
    end

    if ( gearRating and gearRating > 0 ) then
        GameTooltip:AddLine(format("Gear Rating: %u", gearRating));
    end

    if ( avgILVL and avgILVL > 0 ) then
        GameTooltip:AddLine(format(STAT_AVERAGE_ITEM_LEVEL..": %.02f", avgILVL));
    end

    if ( defenseRating and defenseRating > 0 ) then
        GameTooltip:AddLine(format("Defense Rating: %u", defenseRating));
    end

    if ( Dodge and Dodge > 0 ) then
        GameTooltip:AddLine(format(STAT_DODGE..": %u", Dodge));
    end

    if ( Block and Block > 0 ) then
        GameTooltip:AddLine(format(SHIELD_BLOCK_TEMPLATE, Block));
    end

    if ( Parry and Parry > 0 ) then
        GameTooltip:AddLine(format(STAT_PARRY..": %u", Parry));
    end

    if ( Haste and Haste > 0 ) then
        GameTooltip:AddLine(format(STAT_HASTE..": %u", Haste));
    end

    if ( Expertise and Expertise > 0 ) then
        GameTooltip:AddLine(format(STAT_EXPERTISE..": %.02f", Expertise).."%");
    end

    GameTooltip:Show();
end

function GetSpecString(spec)
    if spec == nil or spec == 0 then return "Unknown spec" end
    local _, spec = GetSpecializationInfoByID(spec);
    return spec;
end

function GetClassColorString(class)
    local classColor = RAID_CLASS_COLORS[class];

    -- Sometimes it's nil for no reason
    if ( not classColor ) then
        classColor = NORMAL_FONT_COLOR;
    end

    return ColorToString(classColor);
end

function ColorToString(color)
    return format("ff%.2x%.2x%.2x", color.r * 255, color.g * 255, color.b * 255);
end

function GetPlayerInfoString(level, class, spec, className)
    return format(PLAYER_LEVEL, level, GetClassColorString(class), GetSpecString(spec), className)
end

function GetPlayerInfoStringWithIlvl(name, level, spec, className, ilvl, color)
    local colorStr = ColorToString(color);
    local str = format(PLAYER_LEVEL, level, colorStr, GetSpecString(spec), className);
    return format(NAME_ILVL_TEMPLATE, colorStr, name, str, ilvl);
end

for i=1, NUM_LFR_LIST_BUTTONS do
    local button = _G["LFRBrowseFrameListButton"..i];
    button:SetScript("OnEnter", MyFunction);
    button:SetSize(410, 16);
    local tex = button:GetHighlightTexture()
    tex:SetSize(410, 16);

    local fs = button:CreateFontString("LFRBrowseFrameListButton"..i.."ILevel", "ARTWORK", "GameFontHighlightSmall")
    fs:SetSize(40, 14);
    fs:SetPoint("LEFT", "LFRBrowseFrameListButton"..i.."PartyIcon", "RIGHT", 9, 0);
    button.ilvl = fs;
end

local LFRBrowseFrameListButton_SetData_Old = LFRBrowseFrameListButton_SetData;

function MyLFRBrowseFrameListButton_SetData(button, index)
    LFRBrowseFrameListButton_SetData_Old(button, index);

    local ilvl = select(32, SearchLFGGetResults(index)) or 0;
    button.ilvl:SetText(format("%u ilvl", ilvl));
end

LFRBrowseFrameListButton_SetData = MyLFRBrowseFrameListButton_SetData

-- Scroll Bar Fix
--LFRBrowseFrameListScrollFrame:SetPoint("TOPLEFT", LFRBrowseFrameListButton1, "TOPLEFT", 21, 0);
--LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", LFRBrowseFrameListButton19, "BOTTOMRIGHT", 18, -31);

LFRBrowseFrameListScrollFrame:SetPoint("TOPRIGHT", -31, 0)
LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", 0, 29)

-- Test stuff
local LFRFrame_SetActiveTab_Old = LFRFrame_SetActiveTab

function MyLFRFrame_SetActiveTab(tab)
    LFRFrame_SetActiveTab_Old(tab)

    if tab == 1 then
        RaidBrowserFrame:SetSize(350, 450);
    else
        RaidBrowserFrame:SetSize(450, 450);
    end
end
    
LFRFrame_SetActiveTab = MyLFRFrame_SetActiveTab

function LFGList_MyFilterFunction(dungeonID, maxLevelDiff)
	local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, repAmount, forceHide = GetLFGDungeonInfo(dungeonID);
	local level = UnitLevel("player");

	-- Check whether we're initialized yet
	if ( not LFGLockList ) then
		return false;
	end

	-- Sometimes we want to force hide even if the server thinks we can join (e.g. there are certain dungeons where you can only join from the NPCs, so we don't want to show them in the UI)
	if ( forceHide ) then
		return false;
	end

	-- If the server tells us we can join, we won't argue
	if ( not LFGLockList[dungeonID] ) then
		return true;
	end

	-- If this doesn't have a header, we won't display it
	if ( groupID == 0 ) then
		return false;
	end

	-- If we don't have the right expansion, we won't display it
	if ( EXPANSION_LEVEL < expansionLevel ) then
		return false;
	end

	-- If we're too high above the recommended level, we won't display it
	--if ( level - maxLevelDiff > recLevel ) then
	--	return false;
	--end

	-- If we're not within the hard level requirements, we won't display it
	--if ( level < minLevel or level > maxLevel ) then
	--	return false;
	--end

	-- If we're the wrong faction, we won't display it.
	if ( LFGLockList[dungeonID] == LFG_INSTANCE_INVALID_WRONG_FACTION ) then
		return false;
	end

	return true;
end

function LFRQueueFrame_MyUpdate()
	local mode, submode = GetLFGMode(LE_LFG_CATEGORY_LFR);

	local checkedList;
	if ( RaidBrowser_IsEmpowered() and mode ~= "listed") then
		checkedList = LFGEnabledList;
	else
		checkedList = LFGQueuedForList[LE_LFG_CATEGORY_LFR];
	end

	LFRRaidList = GetLFRChoiceOrder(LFRRaidList);

	LFGQueueFrame_UpdateLFGDungeonList(LFRRaidList, LFRHiddenByCollapseList, checkedList, LFGList_MyFilterFunction, LFR_MAX_SHOWN_LEVEL_DIFF);
	
	LFRQueueFrameSpecificList_Update();
end

LFRQueueFrame_Update = LFRQueueFrame_MyUpdate

--local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, bonusRepAmount, forceHide, numRequiredPlayers = GetLFGDungeonInfo(value);

function LFRQueueFrameSpecificListButton_MySetDungeon(button, dungeonID, mode, submode)
	local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday = GetLFGDungeonInfo(dungeonID);
	button.id = dungeonID;
	if ( LFGIsIDHeader(dungeonID) ) then
		button.instanceName:SetText(name);
		button.instanceName:SetFontObject(QuestDifficulty_Header);
		button.instanceName:SetPoint("RIGHT", button, "RIGHT", 0, 0);
		button.level:Hide();

		if ( subtypeID == LFG_SUBTYPEID_HEROIC ) then
			button.heroicIcon:Show();
			button.instanceName:SetPoint("LEFT", button.heroicIcon, "RIGHT", 0, 1);
		else
			button.heroicIcon:Hide();
			button.instanceName:SetPoint("LEFT", 40, 0);
		end

		button.expandOrCollapseButton:Show();
		local isCollapsed = LFGCollapseList[dungeonID];
		button.isCollapsed = isCollapsed;
		if ( isCollapsed ) then
			button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP");
		else
			button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP");
		end
	else
		button.instanceName:SetText(name);
		button.instanceName:SetPoint("RIGHT", button.level, "LEFT", -10, 0);

		button.heroicIcon:Hide();
		button.instanceName:SetPoint("LEFT", 40, 0);

		if ( minLevel == maxLevel ) then
			button.level:SetText(format(LFD_LEVEL_FORMAT_SINGLE, minLevel));
		else
			button.level:SetText(format(LFD_LEVEL_FORMAT_RANGE, minLevel, maxLevel));
		end
		button.level:Show();
		local difficultyColor = GetQuestDifficultyColor(recLevel);
		button.level:SetFontObject(difficultyColor.font);

		if ( mode == "rolecheck" or mode == "queued" or mode == "listed" or mode == "suspended" or not RaidBrowser_IsEmpowered()) then
			button.instanceName:SetFontObject(QuestDifficulty_Header);
		else
			button.instanceName:SetFontObject(difficultyColor.font);
		end

		button.expandOrCollapseButton:Hide();

		button.isCollapsed = false;
	end

	if ( not LFGLockList[dungeonID] or LFR_CanQueueForLockedInstances() or (LFR_CanQueueForRaidLockedInstances() and LFGLockList[dungeonID] == LFG_INSTANCE_INVALID_RAID_LOCKED) ) then
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
	else
		button.enableButton:Show();
		button.lockedIndicator:Hide();
	end

	local enableState;
	if ( mode == "queued" or mode == "listed" or mode == "suspended" ) then
		enableState = LFGQueuedForList[LE_LFG_CATEGORY_LFR][dungeonID];
	elseif ( not LFR_CanQueueForMultiple() ) then
		enableState = dungeonID == LFRQueueFrame.selectedLFM;
	else
		enableState = LFGEnabledList[dungeonID];
	end

	if ( LFR_CanQueueForMultiple() ) then
		if ( enableState == 1 ) then	--Some are checked, some aren't.
			button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Up");
			button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Disabled");
		else
			button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
			button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
		end
		button.enableButton:SetChecked(enableState and enableState ~= 0);
	else
		button.enableButton:SetChecked(enableState);
	end

	if ( mode == "rolecheck" or mode == "queued" or mode == "listed" or mode == "suspended" or not RaidBrowser_IsEmpowered() ) then
		button.enableButton:Disable();
	else
		button.enableButton:Enable();
	end
end

LFRQueueFrameSpecificListButton_SetDungeon = LFRQueueFrameSpecificListButton_MySetDungeon
