local ADDON_NAME, ADDON_TABLE = ...;

local warnedGroups = {};

-- /script LFGListFrame.CategorySelection:Hide()
-- /script LFGListFrame.SearchPanel:Show()
-- /script LFGListFrame.ApplicationViewer:Hide()
-- /script LFGListFrame.ApplicationViewer:Hide() LFGListFrame.SearchPanel:Show()
-- /script LFGListFrame.ApplicationViewer:Show() LFGListFrame.SearchPanel:Hide()

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

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	MyLFGListCategorySelection_StartFindGroup(panel);
end

function MyLFGListCategorySelection_StartFindGroup(self, questID)
	local baseFilters = self:GetParent().baseFilters;

	local searchPanel = self:GetParent().SearchPanel;
	MyLFGListSearchPanel_Clear(searchPanel);
	--searchPanel.SearchBox:SetText(searchText or "");
	if questID then
		C_LFGList.SetSearchToQuestID(questID);
	end
	LFGListSearchPanel_SetCategory(searchPanel, self.selectedCategory, self.selectedFilters, baseFilters);
	MyLFGListSearchPanel_DoSearch(searchPanel);
	LFGListFrame_SetActivePanel(self:GetParent(), searchPanel);
end

function MyLFGListSearchPanel_Clear(self)
	--C_LFGList.ClearSearchResults(); -- can't do 2 secure calls from unsecure environment in one hardware event...
	--self.SearchBox:SetText("");
	C_LFGList.ClearSearchTextFields();
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
		C_LFGList.SetSearchToActivity(activity);
		C_LFGList.Search(self.categoryID, self.filters, self.preferredFilters, languages);
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
		C_LFGList.SetSearchToActivity(activity);
		C_LFGList.Search(self.categoryID, 0, 0, languages);
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

	local numResults = 0;
	local newResults = {};

	for i=1, #self.results do
		local searchResultInfo = C_LFGList.GetSearchResultInfo(self.results[i]);
		local isSpam = LFRAdvanced_IsSpam(searchResultInfo.name, searchResultInfo.comment);
		if (searchText ~= "" and LFRAdvanced_MatchSearchResult(searchText, searchResultInfo.activityID, searchResultInfo.name, searchResultInfo.comment, searchResultInfo.requiredItemLevel, searchResultInfo.leaderName) and not isSpam) or (searchText == "" and not isSpam) then
			numResults = numResults + 1;
			newResults[numResults] = self.results[i];
		end
	end

	--print("LFRA: totalResults "..self.totalResults..", received "..#self.results..", displayed "..numResults);
	self.totalResults, self.results = numResults, newResults;

	-- New groups warning
	if ADDON_TABLE.updateFunc then
		local numNotWarned = 0;
		for i=1, #self.results do
			local searchResultInfo = C_LFGList.GetSearchResultInfo(self.results[i]);
			if searchResultInfo.leaderName and not warnedGroups[searchResultInfo.leaderName] then
				warnedGroups[searchResultInfo.leaderName] = true;
				numNotWarned = numNotWarned + 1;
				print("New group "..searchResultInfo.name.." by "..searchResultInfo.leaderName);
			end
		end

		if numNotWarned > 0 then
			PlaySound(SOUNDKIT.READY_CHECK, "Master");
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

function MyLFGListUtil_SetSearchEntryTooltip(tooltip, resultID, autoAcceptOption)
	--print("MyLFGListUtil_SetSearchEntryTooltip")
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	local activityName, shortName, categoryID, groupID, minItemLevel, filters, minLevel, maxPlayers, displayType, orderIndex, useHonorLevel = C_LFGList.GetActivityInfo(searchResultInfo.activityID);
	local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID);
	tooltip:SetText(searchResultInfo.name, 1, 1, 1, true);
	tooltip:AddLine(activityName);
	if ( searchResultInfo.comment and searchResultInfo.comment == "" and searchResultInfo.questID ) then
		searchResultInfo.comment = LFGListUtil_GetQuestDescription(searchResultInfo.questID);
	end
	if ( searchResultInfo.comment ~= "" ) then
		tooltip:AddLine(string.format(LFG_LIST_COMMENT_FORMAT, searchResultInfo.comment), LFG_LIST_COMMENT_FONT_COLOR.r, LFG_LIST_COMMENT_FONT_COLOR.g, LFG_LIST_COMMENT_FONT_COLOR.b, true);
	end
	tooltip:AddLine(" ");
	if ( searchResultInfo.requiredItemLevel > 0 ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_ILVL, searchResultInfo.requiredItemLevel));
	end
	if ( useHonorLevel and searchResultInfo.requiredHonorLevel > 0 ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_HONOR_LEVEL, searchResultInfo.requiredHonorLevel));
	end
	if ( searchResultInfo.voiceChat ~= "" ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_VOICE_CHAT, searchResultInfo.voiceChat), nil, nil, nil, true);
	end
	if ( searchResultInfo.requiredItemLevel > 0 or (useHonorLevel and searchResultInfo.requiredHonorLevel > 0) or searchResultInfo.voiceChat ~= "" ) then
		tooltip:AddLine(" ");
	end

	if ( searchResultInfo.leaderName ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_LEADER, searchResultInfo.leaderName));
	end
	if ( searchResultInfo.age > 0 ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_AGE, SecondsToTime(searchResultInfo.age, false, false, 1, false)));
	end

	if ( searchResultInfo.leaderName or searchResultInfo.age > 0 ) then
		tooltip:AddLine(" ");
	end

	if ( LFRAdvancedOptions.ShowMemberInfo ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_MEMBERS, searchResultInfo.numMembers, memberCounts.TANK, memberCounts.HEALER, memberCounts.DAMAGER));
		local roleClasses = {};
		for i=1, searchResultInfo.numMembers do
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
			--tooltip:AddLine(_G[role]..":");
			for class, cnt in pairs(classcnts) do
				local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
				tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_CLASS_ROLE.." - %d", LOCALIZED_CLASS_NAMES_MALE[class], _G[role], cnt), classColor.r, classColor.g, classColor.b);
			end
			table.wipe(classcnts);
		end
		table.wipe(roleClasses);
	else
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_MEMBERS, searchResultInfo.numMembers, memberCounts.TANK, memberCounts.HEALER, memberCounts.DAMAGER));
	end

	if ( searchResultInfo.numBNetFriends + searchResultInfo.numCharFriends + searchResultInfo.numGuildMates > 0 ) then
		tooltip:AddLine(" ");
		tooltip:AddLine(LFG_LIST_TOOLTIP_FRIENDS_IN_GROUP);
		tooltip:AddLine(LFGListSearchEntryUtil_GetFriendList(resultID), 1, 1, 1, true);
	end

	local completedEncounters = C_LFGList.GetSearchResultEncounterInfo(resultID);
	if ( completedEncounters and #completedEncounters > 0 ) then
		tooltip:AddLine(" ");
		tooltip:AddLine(LFG_LIST_BOSSES_DEFEATED);
		for i=1, #completedEncounters do
			tooltip:AddLine(completedEncounters[i], RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		end
	end

	autoAcceptOption = autoAcceptOption or LFG_LIST_UTIL_ALLOW_AUTO_ACCEPT_LINE;

	if autoAcceptOption == LFG_LIST_UTIL_ALLOW_AUTO_ACCEPT_LINE and searchResultInfo.autoAccept then
		tooltip:AddLine(" ");
		tooltip:AddLine(LFG_LIST_TOOLTIP_AUTO_ACCEPT, LIGHTBLUE_FONT_COLOR:GetRGB());
	end

	if ( searchResultInfo.isDelisted ) then
		tooltip:AddLine(" ");
		tooltip:AddLine(LFG_LIST_ENTRY_DELISTED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
	end

	tooltip:Show();
end

hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", MyLFGListUtil_SetSearchEntryTooltip);

-- fix name if created with addon by questid
function MyLFGListSearchEntry_Update(self)
	local resultID = self.resultID;
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	local qId = tonumber(searchResultInfo.name);
	--print("MyLFGListSearchEntry_Update", resultID, searchResultInfo.activityID, searchResultInfo.name, searchResultInfo.questID, qId)
	if qId and searchResultInfo.questID then
		-- we never get here, oh well, fuck Blizzard...
		--print("qId and questID")
		local qName = QuestUtils_GetQuestName(searchResultInfo.questID);
		searchResultInfo.name = qName ~= "" and qName or searchResultInfo.name;
	elseif qId and (qId > 0 and qId < 100000) then
		--print("qId")
		local qName = QuestUtils_GetQuestName(qId);
		searchResultInfo.name = qName ~= "" and qName or searchResultInfo.name;
	end
	self.Name:SetText(searchResultInfo.name);
end

hooksecurefunc("LFGListSearchEntry_Update", MyLFGListSearchEntry_Update);

--local LFGListSearchPanel_OnShowOld = LFGListSearchPanel_OnShow;

function MyLFGListSearchPanel_OnShow(self)
	--print("MyLFGListSearchPanel_OnShow");
	--LFGListSearchPanel_OnShowOld(self);

	-- fix results not being filtered after reopening frame
	MyLFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);

	--local text = LFRAdvancedOptions.LastSearchText;
	--if text and text ~= "" then
	--	self.SearchBox:SetText(text);
	--end

	--local buttons = self.ScrollFrame.buttons;
	--for i = 1, #buttons do
	--	buttons[i]:SetScript("OnEnter", MyLFGListSearchEntry_OnEnter);
	--end
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
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
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
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		local activity = LFGListDropDown.activeValue;
		if activity <= 0 then
			LFGListSearchPanel_DoSearch(self:GetParent());
		else
			MyLFGListSearchPanel_DoSearch(self:GetParent());
		end
	end
end)

local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
	local playerRole = GetSpecializationRole(GetSpecialization());
	return roles[roleRemainingKeyLookup[playerRole]] > 0;
end

function MyLFGListUtil_SortSearchResultsCB(searchResultID1, searchResultID2)
	local searchResultInfo1 = C_LFGList.GetSearchResultInfo(searchResultID1);
	local searchResultInfo2 = C_LFGList.GetSearchResultInfo(searchResultID2);

	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(searchResultID1);
	local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(searchResultID2);

	-- Groups with your current role available are preferred
	if (hasRemainingRole1 ~= hasRemainingRole2) then
		return hasRemainingRole1;
	end

	--If one has more friends, do that one first
	if ( searchResultInfo1.numBNetFriends ~= searchResultInfo2.numBNetFriends ) then
		return searchResultInfo1.numBNetFriends > searchResultInfo2.numBNetFriends;
	end

	if ( searchResultInfo1.numCharFriends ~= searchResultInfo2.numCharFriends ) then
		return searchResultInfo1.numCharFriends > searchResultInfo2.numCharFriends;
	end

	if ( searchResultInfo1.numGuildMates ~= searchResultInfo2.numGuildMates ) then
		return searchResultInfo1.numGuildMates > searchResultInfo2.numGuildMates;
	end

	--If we aren't sorting by anything else, just go by ID
	--return searchResultID1 < searchResultID2;
	return searchResultInfo1.age < searchResultInfo2.age;
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

local function LinkAchievement(_, name)
	if not name then return end
	local achievementLink = GetAchievementLink(12536);
	if achievementLink then
		SendChatMessage(achievementLink, "WHISPER", nil, name);
	end
end

local LFGListUtil_GetSearchEntryMenu_Old = LFGListUtil_GetSearchEntryMenu;

function LFGListUtil_GetSearchEntryMenu(resultID)
	local retVal = LFGListUtil_GetSearchEntryMenu_Old(resultID);
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	--print("Debug", resultID, searchResultInfo.activityID)
	-- Whisper leader
	--retVal[2].disabled = not searchResultInfo.leaderName;
	--retVal[2].tooltipTitle = nil;
	--retVal[2].tooltipText = nil;

	local achLinkEnabled = searchResultInfo.activityID == 494 or searchResultInfo.activityID == 495 or searchResultInfo.activityID == 496;

	-- Link Achievement
	local index = 4;
	retVal[index] = {};
	retVal[index].text = "Link Uldir \"Curve\" Achievement to leader";
	retVal[index].func = LinkAchievement;
	retVal[index].arg1 = searchResultInfo.leaderName;
	retVal[index].disabled = not searchResultInfo.leaderName or not achLinkEnabled;
	retVal[index].notCheckable = true;

	-- Copy leader name
	index = index + 1;
	retVal[index] = {};
	retVal[index].text = "Copy leader name";
	retVal[index].func = CopyPlayerName;
	retVal[index].arg1 = searchResultInfo.leaderName;
	retVal[index].disabled = not searchResultInfo.leaderName;
	retVal[index].notCheckable = true;

	-- Cancel
	index = index + 1;	
	retVal[index] = {};
	retVal[index].text = CANCEL;
	retVal[index].notCheckable = true;

	return retVal;
end

local LFGListUtil_GetApplicantMemberMenu_Old = LFGListUtil_GetApplicantMemberMenu;
local locale = GetLocale();

function LFGListUtil_GetApplicantMemberMenu(applicantID, memberIdx)
	local retVal = LFGListUtil_GetApplicantMemberMenu_Old(applicantID, memberIdx);
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx);
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

function MyLFGListApplicationViewer_UpdateInfo(self)
	local entryData = C_LFGList.GetActiveEntryInfo();
	--Update the AutoAccept button
	self.AutoAcceptButton:SetChecked(entryData.autoAccept);
	--print("C_LFGList.CanActiveEntryUseAutoAccept", C_LFGList.CanActiveEntryUseAutoAccept());
	--if ( not C_LFGList.CanActiveEntryUseAutoAccept() ) then
	--	self.AutoAcceptButton:Hide();
	--elseif ( UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) ) then
	if ( UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) ) then
		self.AutoAcceptButton:Show();
		self.AutoAcceptButton:Enable();
		self.AutoAcceptButton.Label:SetFontObject(GameFontHighlightSmall);
	elseif ( UnitIsGroupAssistant("player", LE_PARTY_CATEGORY_HOME) ) then
		self.AutoAcceptButton:Show();
		self.AutoAcceptButton:Disable();
		self.AutoAcceptButton.Label:SetFontObject(GameFontDisableSmall);
	else
		self.AutoAcceptButton:SetShown(entryData.autoAccept);
		self.AutoAcceptButton:Disable();
		self.AutoAcceptButton.Label:SetFontObject(GameFontDisableSmall);
	end
end

--hooksecurefunc("LFGListApplicationViewer_UpdateInfo", MyLFGListApplicationViewer_UpdateInfo);
