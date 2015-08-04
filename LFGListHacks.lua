local refreshTicker

LFGListCustomSearchBox:SetParent(LFGListFrame.SearchPanel);
LFGListCustomSearchBox:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.CategoryName, "BOTTOMLEFT", 4, -30);
LFGListCustomSearchBox.Instructions:SetText(FILTER);

LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", -1, -102);

LFGListFrame.CategorySelection.FindGroupButton:SetScript("OnClick", function(self)
	--print("LFGListCategorySelection_FindGroup");
	LFGListDropDown.activeValue = 0;
	LFGListCategorySelectionFindGroupButton_OnClick(self)
end)

function LFGListSearchPanel_DoSearch(self)
	--print("LFGListSearchPanel_DoSearch");

	if LFRAdvancedOptions.AutoRefresh and not refreshTicker then 
		refreshTicker = C_Timer.NewTicker(30, function() LFGListFrame.SearchPanel.RefreshButton:Click() end)
	end

	local activity = LFGListDropDown.activeValue;
	local languages = C_LFGList.GetLanguageSearchFilter();

	if LFGListFrame.SearchPanel:IsVisible() then
		--print("LFGListFrame.SearchPanel:IsVisible()")
		LFRAdvancedOptions.LastSearchText = self.SearchBox:GetText();
	end

	if activity <= 0 then
		-- Blizzard default code
		LFGListDropDown_UpdateText(activity);
		C_LFGList.Search(self.categoryID, LFRAdvancedOptions.LastSearchText, self.filters, self.preferredFilters, languages);
	else
		-- activity search from dropdown
		local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activity);
		self.categoryID = categoryID;
		--local oldScript = self.SearchBox:GetScript("OnTextChanged");
		--self.SearchBox:SetScript("OnTextChanged", nil);
		--self.SearchBox:SetText(fullName);
		--self.SearchBox:SetScript("OnTextChanged", oldScript);
		LFGListDropDown_UpdateText(activity, fullName);
		C_LFGList.Search(self.categoryID, fullName, 0, 0, languages);
	end

	self.searching = true;
	self.searchFailed = false;
	self.selectedResult = nil;
	LFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);
end

function LFGListSearchPanel_UpdateResultList(self)
	--print("LFGListSearchPanel_UpdateResultList");
	local searchText = LFGListCustomSearchBox:GetText();

	if searchText ~= "" then
		--print("SearchText: "..searchText);

		self.totalResults, self.results = C_LFGList.GetSearchResults();

		local numResults = 0;
		local newResults = {};

		for i=1, #self.results do
			if LFRAdvanced_MatchSearchResult(searchText, self.results[i]) then
				numResults = numResults + 1
				newResults[numResults] = self.results[i];
			end
		end

		--print("totalResults: "..self.totalResults..", received: "..#self.results..", displayed: "..numResults)
		self.totalResults, self.results = numResults, newResults;
	else
		self.totalResults, self.results = C_LFGList.GetSearchResults();
		--print("totalResults: "..self.totalResults..", received: "..#self.results)
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
	local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(resultID);
	local activityName, shortName, categoryID, groupID, minItemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID);
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
	if ( voiceChat ~= "" ) then
		GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_VOICE_CHAT, voiceChat), nil, nil, nil, true);
	end
	if ( iLvl > 0 or voiceChat ~= "" ) then
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
		for i=1, numMembers do
			local role, class, classLocalized = C_LFGList.GetSearchResultMemberInfo(resultID, i);
			local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
			GameTooltip:AddLine(string.format(LFG_LIST_TOOLTIP_CLASS_ROLE, classLocalized, _G[role]), classColor.r, classColor.g, classColor.b);
		end
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

local LFGListSearchPanel_OnShowOld = LFGListSearchPanel_OnShow;

function MyLFGListSearchPanel_OnShow(self)
	--print("MyLFGListSearchPanel_OnShow");
	LFGListSearchPanel_OnShowOld(self);

	local text = LFRAdvancedOptions.LastSearchText;
	if text then
		self.SearchBox:SetText(text);
	end

	local buttons = self.ScrollFrame.buttons;
	for i = 1, #buttons do
		buttons[i]:SetScript("OnEnter", MyLFGListSearchEntry_OnEnter);
	end

	if LFRAdvancedOptions.AutoRefresh and LFGListFrame.SearchPanel:IsVisible() and not refreshTicker then
		refreshTicker = C_Timer.NewTicker(30, function() LFGListFrame.SearchPanel.RefreshButton:Click() end)
	end
end

function MyLFGListSearchPanel_OnHide(self)
	--print("MyLFGListSearchPanel_OnHide")
	if LFRAdvancedOptions.AutoRefresh then
		refreshTicker:Cancel()
		refreshTicker = nil
	end
end

LFGListFrame.SearchPanel:SetScript("OnShow", MyLFGListSearchPanel_OnShow)
LFGListFrame.SearchPanel:SetScript("OnHide", MyLFGListSearchPanel_OnHide)

function LFGListUtil_SortSearchResultsCB(id1, id2)
	local id1, activityID1, name1, comment1, voiceChat1, iLvl1, age1, numBNetFriends1, numCharFriends1, numGuildMates1, isDelisted1 = C_LFGList.GetSearchResultInfo(id1);
	local id2, activityID2, name2, comment2, voiceChat2, iLvl2, age2, numBNetFriends2, numCharFriends2, numGuildMates2, isDelisted2 = C_LFGList.GetSearchResultInfo(id2);

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

local LFGListUtil_GetSearchEntryMenu_Old = LFGListUtil_GetSearchEntryMenu

function LFGListUtil_GetSearchEntryMenu(resultID)
	local retVal = LFGListUtil_GetSearchEntryMenu_Old(resultID)
	local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName = C_LFGList.GetSearchResultInfo(resultID);
	retVal[2].disabled = not leaderName;
	retVal[2].tooltipTitle = nil;
	retVal[2].tooltipText = nil;
	return retVal
end
