local NAME_ILVL_TEMPLATE = "%s %s (%.02f)";

local GetNumGuildMembers, GetGuildRosterInfo = GetNumGuildMembers, GetGuildRosterInfo;
local GetSpecializationInfoByID = GetSpecializationInfoByID;

LFRAdvanced = {}

if LFRAdvancedOptions == nil then
	LFRAdvancedOptions = {
		ShowStats = true,
		ShowBossKills = true,
		ShowLockouts = true,
		ShowOldRaids = true,
		ShowPartyInfo = true,
		IgnoreLevelReq = false,
	}
end

StaticPopupDialogs["LFRADVANCED_CREATERAID"] = {
	preferredIndex = STATICPOPUPS_NUMDIALOGS,
	text = "You are about to create raid with other players.\nAre you sure?",
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		LFRAdvanced_CreateRaid(false)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
};

local ROLE_ICONS = {
	LEADER  = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:0:16:0:16|t",
	TANK    = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:32:48:0:16|t",
	HEALER  = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:48:64:0:16|t",
	DAMAGER = "|TInterface\\LFGFrame\\LFGRole:12:12:-1:0:64:16:16:32:0:16|t"
}

local mainFrame = CreateFrame("Frame")
local players = {};
local numInvited = 0;
local tankNeeds, healerNeeds, dpsNeeds = 2, 6, 17;

local function table_size(t)
	local n = 0;
	for k, v in pairs(t) do
		n = n + 1;
	end
	return n;
end

local function IU(name, role)
	print("Inviting "..name.." ("..role..")");
	InviteUnit(name);
end

local function LFRA_InvitePlayers(max)
	local count = 0;

	for k, v in pairs(players) do
		if count >= max then break end

		if tankNeeds > 0 and v == TANK then
			tankNeeds = tankNeeds - 1;
			IU(k, v);
			numInvited = numInvited + 1;
			players[k] = nil;
			count = count + 1;
		elseif healerNeeds > 0 and v == HEALER then
			healerNeeds = healerNeeds - 1;
			IU(k, v);
			numInvited = numInvited + 1;
			players[k] = nil;
			count = count + 1;
		elseif dpsNeeds > 0 and v == DAMAGER then
			dpsNeeds = dpsNeeds - 1;
			IU(k, v);
			numInvited = numInvited + 1;
			players[k] = nil;
			count = count + 1;
		elseif v and tankNeeds == 0 and healerNeeds == 0 then
			IU(k, v);
			numInvited = numInvited + 1;
			players[k] = nil;
			count = count + 1;
		end

		if numInvited == 39 then
			break;
		end
	end
	print("Invited "..numInvited.." players.");
end

local function ResetVars()
	table.wipe(players);
	numInvited = 0;
	tankNeeds, healerNeeds, dpsNeeds = 2, 6, 17;
	LFRBrowseFrameCreateRaidButton:Enable();
end

local function EventHandler(self, event, ...)
	if event == "MODIFIER_STATE_CHANGED" then
		if LFRAdvanced.lastOnEnterButton then
			MyLFRBrowseButton_OnEnter(LFRAdvanced.lastOnEnterButton)
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if UnitIsGroupLeader("player") and table_size(players) > 0 then
			if GetNumGroupMembers() > 0 and not IsInRaid() then
				ConvertToRaid();
			elseif IsInRaid() then
				LFRA_InvitePlayers(40-GetNumGroupMembers()-numInvited);
				ResetVars();
			end
		elseif GetNumGroupMembers() == 0 then
			ResetVars();
		end
	end
end

local timer = 10;
local function UpdateHandler(self, elapsed)
	timer = timer - elapsed;
	if timer < 0 then
		timer = 10;
		ResetVars();
		mainFrame:SetScript("OnUpdate", nil)
	end
end

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

local function GetSpecString(specID)
	if not specID or specID == 0 then
		return "Unknown spec", "Unknown class", "DAMAGER"
	end
	local _, spec, _, _, _, role, class = GetSpecializationInfoByID(specID);
	return spec, class, role;
end

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
	if ( not LFRAdvancedOptions.IgnoreLevelReq and level < minLevel ) then
		return false;
	end

	return true;
end

function LFRAdvanced_CreateRaid(click)
	if click and not IsInRaid() then
		StaticPopup_Show("LFRADVANCED_CREATERAID");
		return;
	end

	local joinedId = SearchLFGGetJoinedID() or 0;
	if joinedId == 0 then
		print("Please select world boss from dropdown menu!");
		return;
	elseif joinedId ~= 767 and joinedId ~= 768 then
	--if joinedId ~= 358  then
		local dun = GetLFGDungeonInfo(joinedId);
		print("Can't create raid for this LFG id ("..(dun or "Unknown")..")");
		return;
	end

	print("Creating raid for "..GetLFGDungeonInfo(joinedId));

	local numResults, totalResults = SearchLFGGetNumResults();

	if numResults == 0 then
		print("List for "..GetLFGDungeonInfo(joinedId).." is empty");
		return;
	end

	LFRBrowseFrameCreateRaidButton:Disable();

	local tanks, healers, dps = 0, 0, 0;

	for i = 1, numResults do
		local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isIneligible, isLeader, isTank, isHealer, isDamage, bossKills, specID, isGroupLeader, armor, spellDamage, plusHealing, CritMelee, CritRanged, critSpell, mp5, mp5Combat, attackPower, agility, maxHealth, maxMana, gearRating, avgILevel, defenseRating, dodgeRating, BlockRating, ParryRating, HasteRating, expertise = SearchLFGGetResults(i);
		if name and name ~= UNKNOWN and partyMembers == 0 then
			if isTank then
				players[name] = TANK;
				tanks = tanks + 1;
			elseif isHealer then
				players[name] = HEALER;
				healers = healers + 1;
			elseif isDamage then
				players[name] = DAMAGER;
				dps = dps + 1;
			end
		end
	end

	print(format("We have %u tanks, %u healers and %u dps listed so far", tanks, healers, dps));

	if IsInRaid() then
		if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
			LFRA_InvitePlayers(40-GetNumGroupMembers()-numInvited);
			table.wipe(players);--wipe now to skip GROUP_ROSTER_UPDATE
		else
			print("Can't invite players (not leader or no assist)");
			table.wipe(players);
			LFRBrowseFrameCreateRaidButton:Enable();
			return;
		end
	else
		LFRA_InvitePlayers(4);--initial invite, we need raid group to invite rest
	end

	mainFrame:SetScript("OnUpdate", UpdateHandler)
end

function SaveLFRAOptions()
	LFRAdvancedOptions.ShowStats = LFRAdvancedOptionsFrameShowStats:GetChecked();
	LFRAdvancedOptions.ShowBossKills = LFRAdvancedOptionsFrameShowBossKills:GetChecked();
	LFRAdvancedOptions.ShowLockouts = LFRAdvancedOptionsFrameShowLockouts:GetChecked();
	LFRAdvancedOptions.ShowOldRaids = LFRAdvancedOptionsFrameShowOldRaids:GetChecked();
	LFRAdvancedOptions.ShowPartyInfo = LFRAdvancedOptionsFrameShowPartyInfo:GetChecked();
	LFRAdvancedOptions.IgnoreLevelReq = LFRAdvancedOptionsFrameIgnoreLevelReq:GetChecked();
end

function RefreshLFRAOptions()
	LFRAdvancedOptionsFrameShowStats:SetChecked(LFRAdvancedOptions.ShowStats);
	LFRAdvancedOptionsFrameShowBossKills:SetChecked(LFRAdvancedOptions.ShowBossKills);
	LFRAdvancedOptionsFrameShowLockouts:SetChecked(LFRAdvancedOptions.ShowLockouts);
	LFRAdvancedOptionsFrameShowOldRaids:SetChecked(LFRAdvancedOptions.ShowOldRaids);
	LFRAdvancedOptionsFrameShowPartyInfo:SetChecked(LFRAdvancedOptions.ShowPartyInfo);
	LFRAdvancedOptionsFrameIgnoreLevelReq:SetChecked(LFRAdvancedOptions.IgnoreLevelReq);
end
