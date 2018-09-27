local ADDON_NAME, ADDON_TABLE = ...;

if LFRAdvancedOptions == nil then
	LFRAdvancedOptions = {
		--ServerSideFiltering = false,
		ShowMemberInfo = true,
		--AutoRefresh = false,
		AutoRefreshInterval = 30,
		HideLegionNormals = false,
		HideLegionHeroics = false,
		HideBFANormals = false,
		HideBFAHeroics = false,
		LastSearchText = "",
		SpamWords = { "wowvendor", "foxstore.pro", "prestige-wow" }
	}
end

local mainFrame = CreateFrame("Frame")

local function EventHandler(self, event, ...)
	if event == "MODIFIER_STATE_CHANGED" then

	elseif event == "GROUP_ROSTER_UPDATE" then

	elseif event == "LFG_LIST_JOINED_GROUP" then
		--ADDON_TABLE.StopAutoRefresh()
	elseif event == "ADDON_LOADED" then
		local addon = select(1, ...);
		if addon == ADDON_NAME then
			if not LFRAdvancedOptions.LastSearchText then
				--print("fix")
				LFRAdvancedOptions.LastSearchText = "";
			end
			if not LFRAdvancedOptions.AutoRefreshInterval then
				--print("fix")
				LFRAdvancedOptions.AutoRefreshInterval = 30;
			end
			if not LFRAdvancedOptions.SpamWords then
				--print("fix")
				LFRAdvancedOptions.SpamWords = { "wowvendor", "foxstore.pro", "prestige-wow" };
			end

			LFGListCustomSearchBox.clearButton:SetScript("OnClick", function(btn)
				SearchBoxTemplateClearButton_OnClick(btn);
				--print("clear click!");
				--LFGListSearchPanel_DoSearch(self);
			end);
		end
	end
end

SLASH_LFRA1 = "/lfra"

SlashCmdList["LFRA"] = function(msg, editBox)
	local msgLower = msg:lower();
	if msgLower:find("spamadd") then
		local word = msgLower:sub(9);
		--print(msg, word);
		table.insert(LFRAdvancedOptions.SpamWords, word:lower());
		DEFAULT_CHAT_FRAME:AddMessage("Added word " .. word .. " to spam filter");
	elseif msgLower:find("spamdel") then
		local id = msgLower:sub(9);
		--print(msg, id);
		local word = table.remove(LFRAdvancedOptions.SpamWords, tonumber(id));
		DEFAULT_CHAT_FRAME:AddMessage("Removed word #" ..id .. " (".. word .. ") from spam filter");
	elseif msgLower == "spamlist" then
		for i, word in pairs(LFRAdvancedOptions.SpamWords) do
			DEFAULT_CHAT_FRAME:AddMessage("Spam word #" .. i .. ": " .. word);
		end
	elseif msgLower == "spamclear" then
		table.wipe(LFRAdvancedOptions.SpamWords);
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /lfra spamadd <word> - Add word to spam filter");
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /lfra spamdel <id> - Remove word from spam filter by id");
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /lfra spamlist - List all words in spam filter");
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /lfra spamclear - Clear all words from spam filter");
	end
end

local function OnUpdate(self, elapsed)
	--if ADDON_TABLE.updateFunc then
	--	ADDON_TABLE.updateFunc(elapsed);
	--end
end

--mainFrame:RegisterEvent("MODIFIER_STATE_CHANGED");
--mainFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
--mainFrame:RegisterEvent("LFG_LIST_JOINED_GROUP");
mainFrame:RegisterEvent("ADDON_LOADED");
mainFrame:SetScript("OnEvent", EventHandler);
--mainFrame:SetScript("OnUpdate", OnUpdate);

function SaveLFRAOptions()
	--LFRAdvancedOptions.ServerSideFiltering = LFRAdvancedOptionsFrameServerSideFiltering:GetChecked();
	LFRAdvancedOptions.ShowMemberInfo = LFRAdvancedOptionsFrameShowMemberInfo:GetChecked();
	--LFRAdvancedOptions.AutoRefresh = LFRAdvancedOptionsFrameAutoRefresh:GetChecked();
	--LFRAdvancedOptions.AutoRefreshInterval = LFRAdvancedOptionsFrameAutoRefreshInterval:GetCurrentValue();
	LFRAdvancedOptions.HideLegionNormals = LFRAdvancedOptionsFrameHideLegionNormals:GetChecked();
	LFRAdvancedOptions.HideLegionHeroics = LFRAdvancedOptionsFrameHideLegionHeroics:GetChecked();
	LFRAdvancedOptions.HideBFANormals = LFRAdvancedOptionsFrameHideBFANormals:GetChecked();
	LFRAdvancedOptions.HideBFAHeroics = LFRAdvancedOptionsFrameHideBFAHeroics:GetChecked();
end

function RefreshLFRAOptions()
	--LFRAdvancedOptionsFrameServerSideFiltering:SetChecked(LFRAdvancedOptions.ServerSideFiltering);
	LFRAdvancedOptionsFrameShowMemberInfo:SetChecked(LFRAdvancedOptions.ShowMemberInfo);
	--LFRAdvancedOptionsFrameAutoRefresh:SetChecked(LFRAdvancedOptions.AutoRefresh);
	--LFRAdvancedOptionsFrameAutoRefreshInterval:SetValue(LFRAdvancedOptions.AutoRefreshInterval);
	LFRAdvancedOptionsFrameHideLegionNormals:SetChecked(LFRAdvancedOptions.HideLegionNormals);
	LFRAdvancedOptionsFrameHideLegionHeroics:SetChecked(LFRAdvancedOptions.HideLegionHeroics);
	LFRAdvancedOptionsFrameHideBFANormals:SetChecked(LFRAdvancedOptions.HideBFANormals);
	LFRAdvancedOptionsFrameHideBFAHeroics:SetChecked(LFRAdvancedOptions.HideBFAHeroics);
end

function LFGListCustomSearchBox_OnTextChanged(self)
	--print("LFGListCustomSearchBox_OnTextChanged");
	SearchBoxTemplate_OnTextChanged(self);
	MyLFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel);
	LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
end

function LFGListCustomSearchBox_OnEnterPressed(self)
	--print("LFGListCustomSearchBox_OnEnterPressed");
	self:ClearFocus();
end

function LFRAdvanced_IsSpam(name, comment)
	local commentLower = comment:lower();
	local nameLower = name:lower();
	for _, word in pairs(LFRAdvancedOptions.SpamWords) do
		if commentLower:find(word, 1, true) then return true end
		if nameLower:find(word, 1, true) then return true end
	end
end

function LFRAdvanced_MatchSearchResult(pattern, activityID, name, comment, iLvl, leaderName)
	--if iLvl > 0 and pattern:match("i%d+") then
	--	local i = tonumber(pattern:sub(2));
	--	return iLvl >= i;
	--end

	if iLvl > 0 then
		for m in pattern:gmatch("i%d+") do
			if iLvl < tonumber(m:sub(2)) then
				return false;
			end
			pattern = pattern:gsub(m, '', 1);
		end
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
