local ADDON_NAME, ADDON_TABLE = ...;

if LFRAdvancedOptions == nil then
	LFRAdvancedOptions = {
		ServerSideFiltering = false,
		ShowMemberInfo = true,
		AutoRefresh = false
	}
end

--local mainFrame = CreateFrame("Frame")

local function EventHandler(self, event, ...)
	if event == "MODIFIER_STATE_CHANGED" then

	elseif event == "GROUP_ROSTER_UPDATE" then

	elseif event == "ADDON_LOADED" then
		local addon = select(1, ...);
		if addon == ADDON_NAME then

		end
	end
end

--mainFrame:RegisterEvent("MODIFIER_STATE_CHANGED");
--mainFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
--mainFrame:RegisterEvent("ADDON_LOADED");
--mainFrame:SetScript("OnEvent", EventHandler);

function SaveLFRAOptions()
	LFRAdvancedOptions.ServerSideFiltering = LFRAdvancedOptionsFrameServerSideFiltering:GetChecked();
	LFRAdvancedOptions.ShowMemberInfo = LFRAdvancedOptionsFrameShowMemberInfo:GetChecked();
	LFRAdvancedOptions.AutoRefresh = LFRAdvancedOptionsFrameAutoRefresh:GetChecked();
	--LFRAdvancedOptions.ShowOldRaids = LFRAdvancedOptionsFrameShowOldRaids:GetChecked();
	--LFRAdvancedOptions.ShowPartyInfo = LFRAdvancedOptionsFrameShowPartyInfo:GetChecked();
	--LFRAdvancedOptions.IgnoreLevelReq = LFRAdvancedOptionsFrameIgnoreLevelReq:GetChecked();
	--LFRAdvancedOptions.CreateRaid = LFRAdvancedOptionsFrameCreateRaid:GetChecked();
end

function RefreshLFRAOptions()
	LFRAdvancedOptionsFrameServerSideFiltering:SetChecked(LFRAdvancedOptions.ServerSideFiltering);
	LFRAdvancedOptionsFrameShowMemberInfo:SetChecked(LFRAdvancedOptions.ShowMemberInfo);
	LFRAdvancedOptionsFrameAutoRefresh:SetChecked(LFRAdvancedOptions.AutoRefresh);
	--LFRAdvancedOptionsFrameShowOldRaids:SetChecked(LFRAdvancedOptions.ShowOldRaids);
	--LFRAdvancedOptionsFrameShowPartyInfo:SetChecked(LFRAdvancedOptions.ShowPartyInfo);
	--LFRAdvancedOptionsFrameIgnoreLevelReq:SetChecked(LFRAdvancedOptions.IgnoreLevelReq);
	--LFRAdvancedOptionsFrameCreateRaid:SetChecked(LFRAdvancedOptions.CreateRaid);
end

function LFRAdvanced_MatchSearchResult(pattern, resultID)
	local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(resultID);

	if iLvl > 0 and pattern:match("i%d+") then
		local i = tonumber(pattern:sub(2));
		return iLvl >= i;
	end

	local activityName = C_LFGList.GetActivityInfo(activityID);
	local text = activityName:lower().." "..name:lower().." "..comment:lower().." "..(leaderName and leaderName:lower() or "");
	--print(id.." : "..text);
	return LFRAdvanced_MatchString(pattern:lower(), text);
end

function LFRAdvanced_GetMatchTokens(pattern)
	local include = {};
	local exclude = {};
	local possible = {};

	local words = {};
	for word in pattern:gmatch("%S+") do
		table.insert(words, word);
	end

	for i,word in pairs(words) do
		local firstChar = word:sub(1,1);
		if firstChar == "+" then
			word = word:sub(2);
			if word ~= "" then
				table.insert(include, word);
			end
		elseif firstChar == "-" then
			word = word:sub(2);
			if word ~= "" then
				table.insert(exclude, word);
			end
		elseif firstChar == "?" then
			word = word:sub(2);
			if word ~= "" then
				table.insert(possible, word);
			end
		else
			table.insert(include, word);
		end
	end

	return include, exclude, possible;
end

function LFRAdvanced_MatchString(pattern, str)
	if not pattern or pattern == "" then
		return true;
	end

	local include, exclude, possible = LFRAdvanced_GetMatchTokens(pattern);

	local matches = true;

	if next(include) then
		for i,word in pairs(include) do
			if not str:find(word) then
				matches = false;
				break;
			end
		end
	end

	if matches and next(exclude) then
		for i,word in pairs(exclude) do
			if str:find(word) then
				matches = false;
				break;
			end
		end
	end

	if matches and next(possible) then
		local strMatch = false;
		for i,word in pairs(possible) do
			if str:find(word) then
				strMatch = true;
				break;
			end
		end
		matches = matches and strMatch;
	end

	return matches;
end
