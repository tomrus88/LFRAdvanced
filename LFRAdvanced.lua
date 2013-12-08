local NAME_ILVL_TEMPLATE = "%s %s (%.02f)";

local RB_RETURN_VALUES_START_PLAYER = 15;
local RB_RETURN_VALUES_START_PARTY = 10;

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
	if not specID or specID == 0 then return "Unknown spec", "Unknown class" end
	local _, spec, _, _, _, _, class = GetSpecializationInfoByID(specID);
	return spec, class;
end

function GetPlayerInfoString(level, spec, className)
	local specName, class = GetSpecString(spec);
	local color = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or "ffffd200"
	return format(PLAYER_LEVEL, level, color, specName, className)
end

function GetPlayerInfoStringWithIlvl(name, level, spec, className, ilvl, color)
	local str = GetPlayerInfoString(level, spec, className)
	return color..format(NAME_ILVL_TEMPLATE, name, str, ilvl)..FONT_COLOR_CODE_CLOSE;
end

function MyLFGList_FilterFunction(dungeonID, maxLevelDiff)
	return true;
end

function MyLFGList_FilterFunction2(dungeonID, maxLevelDiff)
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
