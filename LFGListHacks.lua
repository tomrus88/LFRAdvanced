local ADDON_NAME, ADDON_TABLE = ...;

local warnedGroups = {};

LFGListCustomSearchBox:SetParent(LFGListFrame.SearchPanel);
LFGListCustomSearchBox:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.CategoryName, "BOTTOMLEFT", 4, -30);
LFGListCustomSearchBox.Instructions:SetText(FILTER);

LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", -1, -102);

LFGListFrame.SearchPanel.SearchBox:HookScript("OnTextChanged", function(self, userInput)
	local text = self:GetText();
	--if (text and text ~= "") or userInput then
	LFRAdvancedOptions.LastSearchText = text or "";
	--end
end)

LFGListFrame.CategorySelection.FindGroupButton:SetScript("OnClick", function(self)
	--print("LFGListCategorySelection_FindGroup");
	LFGListDropDown.activeValue = 0;
	MyLFGListCategorySelectionFindGroupButton_OnClick(self);
end)

function MyLFGListCategorySelectionFindGroupButton_OnClick(self)
	local panel = self:GetParent();
	if ( not panel.selectedCategory ) then
		return;
	end

	PlaySound("igMainMenuOptionCheckBoxOn");
	MyLFGListCategorySelection_StartFindGroup(panel);
end

function MyLFGListCategorySelection_StartFindGroup(self, searchText, questID)
	local baseFilters = self:GetParent().baseFilters;

	local searchPanel = self:GetParent().SearchPanel;
	MyLFGListSearchPanel_Clear(searchPanel);
	searchPanel.SearchBox:SetText(searchText or "");
	LFGListSearchPanel_SetCategory(searchPanel, self.selectedCategory, self.selectedFilters, baseFilters);
	MyLFGListSearchPanel_DoSearch(searchPanel);
	LFGListFrame_SetActivePanel(self:GetParent(), searchPanel);
end

function MyLFGListSearchPanel_Clear(self)
	--C_LFGList.ClearSearchResults(); -- can't do 2 secure calls from unsecure environment in one hardware event...
	self.SearchBox:SetText("");
	self.selectedResult = nil;
	MyLFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);
end

function MyLFGListSearchPanel_OnEvent(self, event, ...)
	--print("hooked event handler", event)
	if ( event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" ) then
		StaticPopupSpecial_Hide(LFGListApplicationDialog);
		self.searching = false;
		self.searchFailed = false;
		MyLFGListSearchPanel_UpdateResultList(self);
		LFGListSearchPanel_UpdateResults(self);
	elseif ( event == "LFG_LIST_SEARCH_FAILED" ) then
		self.searching = false;
		self.searchFailed = true;
		MyLFGListSearchPanel_UpdateResultList(self);
		LFGListSearchPanel_UpdateResults(self);
	end
end

LFGListFrame.SearchPanel:HookScript("OnEvent", MyLFGListSearchPanel_OnEvent);

function MyLFGListSearchPanel_DoSearch(self)
	--print("MyLFGListSearchPanel_DoSearch");

	local activity = LFGListDropDown.activeValue;
	--print("MyLFGListSearchPanel_DoSearch", activity, self.categoryID)
	local languages = C_LFGList.GetLanguageSearchFilter();

	if LFGListFrame.SearchPanel:IsVisible() then
		--print("LFGListFrame.SearchPanel:IsVisible()");
		LFRAdvancedOptions.LastSearchText = self.SearchBox:GetText();
	end

	if activity <= 0 then
		-- Blizzard default code
		LFGListDropDown_UpdateText(activity);
		C_LFGList.Search(self.categoryID, LFGListSearchPanel_ParseSearchTerms(LFRAdvancedOptions.LastSearchText), self.filters, self.preferredFilters, languages);
		--print("1")
	else
		-- activity search from dropdown
		local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activity);
		self.categoryID = categoryID;
		--local oldScript = self.SearchBox:GetScript("OnTextChanged");
		--self.SearchBox:SetScript("OnTextChanged", nil);
		--self.SearchBox:SetText(fullName);
		--self.SearchBox:SetScript("OnTextChanged", oldScript);
		LFGListDropDown_UpdateText(activity, fullName);
		C_LFGList.Search(self.categoryID, LFGListSearchPanel_ParseSearchTerms(fullName), 0, 0, languages);
		--print("2")
	end

	self.searching = true;
	self.searchFailed = false;
	self.selectedResult = nil;
	MyLFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);
end

function MyLFGListSearchPanel_UpdateResultList(self)
	--print("MyLFGListSearchPanel_UpdateResultList");
	local searchText = LFGListCustomSearchBox:GetText();

	self.totalResults, self.results = C_LFGList.GetSearchResults();

	if searchText ~= "" then
		--print("SearchText: "..searchText);

		local numResults = 0;
		local newResults = {};

		for i=1, #self.results do
			if LFRAdvanced_MatchSearchResult(searchText, self.results[i]) then
				numResults = numResults + 1;
				newResults[numResults] = self.results[i];
			end
		end

		--print("totalResults: "..self.totalResults..", received: "..#self.results..", displayed: "..numResults);
		self.totalResults, self.results = numResults, newResults;
	end

	-- New groups warning
	if ADDON_TABLE.updateFunc then
		local numNotWarned = 0;
		for i=1, #self.results do
			local _, _, name, _, _, _, _, _, _, _, _, _, leaderName = C_LFGList.GetSearchResultInfo(self.results[i]);
			if leaderName and not warnedGroups[leaderName] then
				warnedGroups[leaderName] = true;
				numNotWarned = numNotWarned + 1;
				print("New group "..name.." by "..leaderName);
			end
		end

		if numNotWarned > 0 then
			PlaySound("ReadyCheck", "Master");
			FlashClientIcon();
		end
	end

	self.applications = C_LFGList.GetApplications();
	LFGListUtil_SortSearchResults(self.results);
end

-- disable autocomplete
--local LFGListSearchPanel_UpdateAutoCompleteOrig = LFGListSearchPanel_UpdateAutoComplete;
--function LFGListSearchPanel_UpdateAutoComplete(self)
--	if LFRAdvancedOptions.ServerSideFiltering then
--		LFGListSearchPanel_UpdateAutoCompleteOrig(self);
--		return;
--	end
--	self.AutoCompleteFrame:Hide();
--	self.AutoCompleteFrame.selected = nil;
--end

function MyLFGListSearchEntry_OnEnter(self)
	--print("LFGListSearchEntry_OnEnter");
	local resultID = self.resultID;
	local id, activityID, name, comment, voiceChat, iLvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(resultID);
	--print(id, name, leaderName or "NONE");
	local activityName, shortName, categoryID, groupID, minItemLevel, filters, minLevel, maxPlayers, displayType, orderIndex, useHonorLevel = C_LFGList.GetActivityInfo(activityID);
	local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 25, 0);
	GameTooltip:SetText(name, 1, 1, 1, true);
	GameTooltip:AddLine(activityName);
	if ( comment ~= "" ) then
		GameTooltip:AddLine(string.format(LFG_LIST_COMMENT_FORMAT, comment), LFG_LIST_COMMENT_FONT_COLOR.r, LFG_LIST_COMMENT_FONT_COLOR.g, LFG_LIST_COMMENT_FONT_COLOR.b, true);
	end
	GameTooltip:AddLine(" ");
	if ( iLvl > 0 ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_ILVL, iLvl));
	end
	if ( useHonorLevel and honorLevel > 0 ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_HONOR_LEVEL, honorLevel));
	end
	if ( voiceChat ~= "" ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_VOICE_CHAT, voiceChat), nil, nil, nil, true);
	end
	if ( iLvl > 0 or (useHonorLevel and honorLevel > 0) or voiceChat ~= "" ) then
		GameTooltip:AddLine(" ");
	end

	if ( leaderName ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_LEADER, leaderName));
	end
	if ( age > 0 ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_AGE, SecondsToTime(age, false, false, 1, false)));
	end

	if ( leaderName or age > 0 ) then
		GameTooltip:AddLine(" ");
	end

	if ( LFRAdvancedOptions.ShowMemberInfo ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_MEMBERS, numMembers, memberCounts.TANK, memberCounts.HEALER, memberCounts.DAMAGER));
		--local classCounts = {};
		--for i=1, numMembers do
		--	local role, class, classLocalized = C_LFGList.GetSearchResultMemberInfo(resultID, i);
		--	local counts = classCounts[class] or {};
		--	classCounts[class] = counts;
		--	if not counts[role] then
		--		counts[role] = 1;
		--	else
		--		counts[role] = counts[role] + 1;
		--	end
		--end
		--for class, rolecnts in pairs(classCounts) do
		--	local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
		--	for role, cnt in pairs(rolecnts) do
		--		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_CLASS_ROLE.." - %d", LOCALIZED_CLASS_NAMES_MALE[class], _G[role], cnt), classColor.r, classColor.g, classColor.b);
		--	end
		--end
		local roleClasses = {};
		for i=1, numMembers do
			local role, class, classLocalized = C_LFGList.GetSearchResultMemberInfo(resultID, i);
			local classcounts = roleClasses[role] or {};
			roleClasses[role] = classcounts;
			if not classcounts[class] then
				classcounts[class] = 1;
			else
				classcounts[class] = classcounts[class] + 1;
			end
		end
		table.sort(roleClasses, function(a,b) return a > b end)
		for role, classcnts in pairs(roleClasses) do
			--GameTooltip:AddLine(_G[role]..":");
			for class, cnt in pairs(classcnts) do
				local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
				GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_CLASS_ROLE.." - %d", LOCALIZED_CLASS_NAMES_MALE[class], _G[role], cnt), classColor.r, classColor.g, classColor.b);
			end
			table.wipe(classcnts);
		end
		table.wipe(roleClasses);
	else
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_MEMBERS, numMembers, memberCounts.TANK, memberCounts.HEALER, memberCounts.DAMAGER));
	end

	if ( numBNetFriends + numCharFriends + numGuildMates > 0 ) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(LFG_LIST_TOOLTIP_FRIENDS_IN_GROUP);
		GameTooltip:AddLine(LFGListSearchEntryUtil_GetFriendList(resultID), 1, 1, 1, true);
	end

	local completedEncounters = C_LFGList.GetSearchResultEncounterInfo(resultID);
	if ( completedEncounters and #completedEncounters > 0 ) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(LFG_LIST_BOSSES_DEFEATED);
		for i=1, #completedEncounters do
			GameTooltip:AddLine(completedEncounters[i], RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		end
	end

	if ( isDelisted ) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(LFG_LIST_ENTRY_DELISTED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
	end

	GameTooltip:Show();
end

--local LFGListSearchPanel_OnShowOld = LFGListSearchPanel_OnShow;

function MyLFGListSearchPanel_OnShow(self)
	--print("MyLFGListSearchPanel_OnShow");
	--LFGListSearchPanel_OnShowOld(self);

	-- fix results not being filtered after reopening frame
	MyLFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);

	local text = LFRAdvancedOptions.LastSearchText;
	if text and text ~= "" then
		self.SearchBox:SetText(text);
	end

	local buttons = self.ScrollFrame.buttons;
	for i = 1, #buttons do
		buttons[i]:SetScript("OnEnter", MyLFGListSearchEntry_OnEnter);
	end
end

function MyLFGListSearchPanel_OnHide(self)
	--print("MyLFGListSearchPanel_OnHide");
	--table.wipe(warnedGroups);
	--local text = self.SearchBox:GetText();
	--if text and text ~= "" then
	--	LFRAdvancedOptions.LastSearchText = text;
	--end
end

LFGListFrame.SearchPanel:HookScript("OnShow", MyLFGListSearchPanel_OnShow);
LFGListFrame.SearchPanel:HookScript("OnHide", MyLFGListSearchPanel_OnHide);
--[[
local intervalTracker = 0;

local function RefreshFunc(elapsed)
	intervalTracker = intervalTracker + elapsed;

	if (intervalTracker > LFRAdvancedOptions.AutoRefreshInterval) then
		intervalTracker = 0;
		LFGListFrame.SearchPanel.RefreshButton:Click();
	end
end

local lfgRefreshButton = LFGListFrame.SearchPanel.RefreshButton;
lfgRefreshButton.texture = lfgRefreshButton:CreateTexture("LFGRefreshButtonTexture", "ARTWORK");
lfgRefreshButton.texture:SetTexture("Interface\\LFGFrame\\LFG-Eye");
lfgRefreshButton.texture:SetAllPoints();
lfgRefreshButton.texture:Hide();
lfgRefreshButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");

local function StartAutoRefresh()
	lfgRefreshButton.Icon:Hide();
	lfgRefreshButton.texture:Show();
	EyeTemplate_StartAnimating(lfgRefreshButton);
	ADDON_TABLE.updateFunc = RefreshFunc;
	print("Auto refreshing list every "..LFRAdvancedOptions.AutoRefreshInterval.." seconds");
end

local function StopAutoRefresh()
	if not ADDON_TABLE.updateFunc then return end
	lfgRefreshButton.Icon:Show();
	lfgRefreshButton.texture:Hide();
	EyeTemplate_StopAnimating(lfgRefreshButton);
	ADDON_TABLE.updateFunc = nil;
	print("No longer auto refreshing list every "..LFRAdvancedOptions.AutoRefreshInterval.." seconds");
end

ADDON_TABLE.StopAutoRefresh = StopAutoRefresh

lfgRefreshButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		PlaySound("igMainMenuOptionCheckBoxOn");
		LFGListSearchPanel_DoSearch(self:GetParent());
	else
		if ADDON_TABLE.updateFunc then
			StopAutoRefresh()
		else
			StartAutoRefresh()
		end
	end
end)
--]]

local lfgRefreshButton = LFGListFrame.SearchPanel.RefreshButton;

lfgRefreshButton:SetScript("OnClick", function(self, button)
	--print("click!")
	if button == "LeftButton" then
		PlaySound("igMainMenuOptionCheckBoxOn");
		MyLFGListSearchPanel_DoSearch(self:GetParent());
	end
end)

function MyLFGListUtil_SortSearchResultsCB(id1, id2)
	local id1, activityID1, name1, comment1, voiceChat1, iLvl1, honorLevel1, age1, numBNetFriends1, numCharFriends1, numGuildMates1, isDelisted1 = C_LFGList.GetSearchResultInfo(id1);
	local id2, activityID2, name2, comment2, voiceChat2, iLvl2, honorLevel2, age2, numBNetFriends2, numCharFriends2, numGuildMates2, isDelisted2 = C_LFGList.GetSearchResultInfo(id2);

	--If one has more friends, do that one first
	if ( numBNetFriends1 ~= numBNetFriends2 ) then
		return numBNetFriends1 > numBNetFriends2;
	end

	if ( numCharFriends1 ~= numCharFriends2 ) then
		return numCharFriends1 > numCharFriends2;
	end

	if ( numGuildMates1 ~= numGuildMates2 ) then
		return numGuildMates1 > numGuildMates2;
	end

	--If we aren't sorting by anything else, just go by ID
	--return id1 < id2;
	return age1 < age2;
end

function MyLFGListUtil_SortSearchResults(results)
	table.sort(results, MyLFGListUtil_SortSearchResultsCB);
end

hooksecurefunc("LFGListUtil_SortSearchResults", MyLFGListUtil_SortSearchResults);

local function CopyPlayerName(_, name)
	if not name then return end
	local ChatFrameEditBox = ChatEdit_ChooseBoxForSend();
	if (not ChatFrameEditBox:IsShown()) then
		ChatEdit_ActivateChat(ChatFrameEditBox);
	end
	ChatFrameEditBox:Insert(name);
	ChatFrameEditBox:HighlightText();
end


local LFGListUtil_GetSearchEntryMenu_Old = LFGListUtil_GetSearchEntryMenu;

function LFGListUtil_GetSearchEntryMenu(resultID)
	local retVal = LFGListUtil_GetSearchEntryMenu_Old(resultID);
	local id, activityID, name, comment, voiceChat, iLvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName = C_LFGList.GetSearchResultInfo(resultID);
	-- Whisper leader
	--retVal[2].disabled = not leaderName;
	--retVal[2].tooltipTitle = nil;
	--retVal[2].tooltipText = nil;
	-- Copy name
	retVal[4].text = "Copy leader name";
	retVal[4].func = CopyPlayerName;
	retVal[4].arg1 = leaderName;
	retVal[4].disabled = not leaderName;
	-- Cancel
	retVal[5] = {};
	retVal[5].text = CANCEL;
	retVal[5].notCheckable = true;
	return retVal;
end

local LFGListUtil_GetApplicantMemberMenu_Old = LFGListUtil_GetApplicantMemberMenu;
local locale = GetLocale();

function LFGListUtil_GetApplicantMemberMenu(applicantID, memberIdx)
	local retVal = LFGListUtil_GetApplicantMemberMenu_Old(applicantID, memberIdx);
	local name, class, localizedClass, level, itemLevel, tank, healer, damage, assignedRole = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx);
	local id, status, pendingStatus, numMembers, isNew, comment = C_LFGList.GetApplicantInfo(applicantID);
	-- Fix bad localization for ignore menu item
	if (locale == "ruRU") then
		-- Ignore
		retVal[4].text = IGNORE;
	end
	-- Copy name
	retVal[5].text = "Copy applicant name";
	retVal[5].func = CopyPlayerName;
	retVal[5].arg1 = name;
	retVal[5].disabled = not name;
	-- Cancel
	retVal[6] = {};
	retVal[6].text = CANCEL;
	retVal[6].notCheckable = true;
	return retVal;
end

--local emptyTable = {};

--function C_LFGList.GetDefaultLanguageSearchFilter()
--	return emptyTable;
--end
