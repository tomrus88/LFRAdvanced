﻿local NAME_ILVL_TEMPLATE = "%s %s (%.02f)";

local RB_RETURN_VALUES_START_PLAYER = 15;
local RB_RETURN_VALUES_START_PARTY = 10;
local GetNumGuildMembers, GetGuildRosterInfo = GetNumGuildMembers, GetGuildRosterInfo;
local GetSpecializationInfoByID = GetSpecializationInfoByID;

LFRAdvanced = {}

if LFRAdvancedOptions == nil then
	LFRAdvancedOptions = {
		ShowStats = true,
		ShowBossKills = true,
	}
end

local RB_RETURN_VALUES = {
	bossKills = 1,
	specID = 2,
	isGroupLeader = 3,
	armor = 4,
	spellDamage = 5,
	plusHealing = 6,
	CritMelee = 7,
	CritRanged = 8,
	critSpell = 9,
	mp5 = 10,
	mp5Combat = 11,
	attackPower = 12,
	agility = 13,
	maxHealth = 14,
	maxMana = 15,
	gearRating = 16,
	avgILevel = 17,
	defenseRating = 18,
	dodgeRating = 19,
	BlockRating = 20,
	ParryRating = 21,
	HasteRating = 22,
	expertise = 23
}

local mainFrame = CreateFrame("Frame")
local creatingRaid = false;

function EventHandler(self, event, ...)
--	if event == "PLAYER_ENTERING_WORLD" then
--		if not IsAddonMessagePrefixRegistered("LFRA") then
--			RegisterAddonMessagePrefix("LFRA")
--		end
--	elseif event == "CHAT_MSG_ADDON" then
--		local prefix, msg, channel, sender = ...;
--		if prefix == "LFRA" then
--			print("Addon msg: "..prefix.." "..msg.." "..channel.." "..sender);
--		end
	if event == "MODIFIER_STATE_CHANGED" then
		if LFRAdvanced.lastOnEnterButton then
			MyLFRBrowseButton_OnEnter(LFRAdvanced.lastOnEnterButton)
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if creatingRaid and GetNumGroupMembers() > 0 and not IsInRaid() then
			ConvertToRaid();
			creatingRaid = false;
		elseif GetNumGroupMembers() == 0 then
			LFRBrowseFrameCreateRaidButton:Enable();
		end
	end
end

--mainFrame:RegisterEvent("CHAT_MSG_ADDON")
--mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
mainFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
mainFrame:SetScript("OnEvent", EventHandler)

function IsGuildie(player)
	local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
	for i = 1, totalMembers do
		local name = GetGuildRosterInfo(i);
		if name == player then
			return true
		end
	end
	return false
end

function GetSpecString(specID)
	if not specID or specID == 0 then
		return "Unknown spec", "Unknown class", "DAMAGER"
	end
	local _, spec, _, _, _, role, class = GetSpecializationInfoByID(specID);
	return spec, class, role;
end

local ROLE_ICONS = {
	LEADER  = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:0:16:0:16|t",
	TANK    = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:32:48:0:16|t",
	HEALER  = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:48:64:0:16|t",
	DAMAGER = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:16:32:0:16|t"
}

function GetPlayerInfoString(level, spec, className)
	local specName, class, role = GetSpecString(spec);
	local color = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or "ffffd200"
	return format(PLAYER_LEVEL, level, color, specName, className), role
end

function GetPlayerInfoStringWithIlvl(name, level, spec, className, ilvl, color)
	local str, role = GetPlayerInfoString(level, spec, className)
	return ROLE_ICONS[role]..color..format(NAME_ILVL_TEMPLATE, name, str, ilvl)..FONT_COLOR_CODE_CLOSE;
end

function MyLFGList_FilterFunction(dungeonID, maxLevelDiff)
	local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, repAmount, forceHide = GetLFGDungeonInfo(dungeonID);
	local level = UnitLevel("player");

	-- If we're not within the hard level requirements, we won't display it
	if ( level < minLevel ) then
		return false;
	end

	return true;
end

local function IU(name)
	print("Inviting "..name);
	InviteUnit(name);
end

function LFRAdvanced_CreateRaid()
	local joinedId = SearchLFGGetJoinedID() or 0;
	if joinedId ~= 767 and joinedId ~= 768 then
	--if joinedId ~= 358  then
		print("Can't create raid for this LFG id ("..joinedId..")");
		return;
	end

	print("Creating raid for "..GetLFGDungeonInfo(joinedId));

	local numResults, totalResults = SearchLFGGetNumResults();

	if numResults == 0 then
		print("List for "..GetLFGDungeonInfo(joinedId).." is empty");
		return;
	end

	local numInvited = 0;

	for i = 1, numResults do
		local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults(i);
		if name and name ~= UNKNOWN and partyMembers == 0 then
			IU(name);
			numInvited = numInvited + 1;
			if numInvited == 1 then
				creatingRaid = true;
				LFRBrowseFrameCreateRaidButton:Disable();
			elseif numInvited == 39 then
				break;
			end
		end
	end
	print("Invited "..numInvited.." players.");
end

function SaveLFRAOptions()
	LFRAdvancedOptions.ShowStats = LFRAdvancedOptionsFrameShowStats:GetChecked();
	LFRAdvancedOptions.ShowBossKills = LFRAdvancedOptionsFrameShowBossKills:GetChecked();
end

function RefreshLFRAOptions()
	LFRAdvancedOptionsFrameShowStats:SetChecked(LFRAdvancedOptions.ShowStats);
	LFRAdvancedOptionsFrameShowBossKills:SetChecked(LFRAdvancedOptions.ShowBossKills);
end
