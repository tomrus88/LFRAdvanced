local ADDON_NAME, ADDON_TABLE = ...;

local warnedGroups = {};

local FACTION_STRINGS = { [0] = FACTION_HORDE, [1] = FACTION_ALLIANCE}; 

-- /script LFGListFrame.CategorySelection:Hide()
-- /script LFGListFrame.SearchPanel:Show()
-- /script LFGListFrame.ApplicationViewer:Hide()
-- /script LFGListFrame.ApplicationViewer:Hide() LFGListFrame.SearchPanel:Show()
-- /script LFGListFrame.ApplicationViewer:Show() LFGListFrame.SearchPanel:Hide()

--LFGListCustomSearchBox:SetParent(LFGListFrame.SearchPanel);
--LFGListCustomSearchBox:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.CategoryName, "BOTTOMLEFT", 4, -30);
--LFGListCustomSearchBox.Instructions:SetText(FILTER);

--LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", -1, -102);

LFGListFrame.SearchPanel.SearchBox:HookScript("OnTextChanged", function(self, userInput)
	local text = self:GetText();
	--if (text and text ~= "") or userInput then
	LFRAdvancedOptions.LastSearchText = text or "";
	--end
end)

LFGListFrame.SearchPanel.SearchBox.clearButton:HookScript("OnClick", function(btn)
	--print("LFGListFrame.SearchPanel.SearchBox.clearButton:HookScript(\"OnClick\")");
	LFGListDropDown.activeValue = 0;
	LFGListDropDown_UpdateText(0);
end);

LFGListFrame.CategorySelection.FindGroupButton:SetScript("OnClick", function(self)
	--print("LFGListCategorySelection_FindGroup");
	LFGListDropDown.activeValue = 0;
	MyLFGListCategorySelectionFindGroupButton_OnClick(self);
end)

function MyLFGListCategorySelectionFindGroupButton_OnClick(self)
	--print("MyLFGListCategorySelectionFindGroupButton_OnClick")
	local panel = self:GetParent();
	if ( not panel.selectedCategory ) then
		return;
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	MyLFGListCategorySelection_StartFindGroup(panel);
end

function MyLFGListCategorySelection_StartFindGroup(self, questID)
	--print("MyLFGListCategorySelection_StartFindGroup")
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
	--print("MyLFGListSearchPanel_Clear");
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

local function ResolveCategoryFilters(categoryID, filters)
	-- Dungeons ONLY display recommended groups.
	if categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
		return bit.band(bit.bnot(Enum.LFGListFilter.NotRecommended), bit.bor(filters, Enum.LFGListFilter.Recommended));
	end

	return filters;
end

function MyLFGListSearchPanel_DoSearch(self)
	--print("MyLFGListSearchPanel_DoSearch");

	local activity = LFGListDropDown.activeValue;
	--print("MyLFGListSearchPanel_DoSearch", activity, self.categoryID)
	local searchText = self.SearchBox:GetText();
	local languages = C_LFGList.GetLanguageSearchFilter();

	if LFGListFrame.SearchPanel:IsVisible() then
		--print("LFGListFrame.SearchPanel:IsVisible()");
		LFRAdvancedOptions.LastSearchText = searchText;
	end

	if activity <= 0 then
		-- Blizzard default code
		LFGListDropDown_UpdateText(activity);
		--C_LFGList.SetSearchToActivity(activity);
		local filters = ResolveCategoryFilters(self.categoryID, self.filters);
		C_LFGList.Search(self.categoryID, filters, self.preferredFilters, languages);
		--print("1")
	else
		-- activity search from dropdown
		--print(activity)
		local activityInfo = C_LFGList.GetActivityInfoTable(activity); -- activityID, questID, showWarmode
		self.categoryID = activityInfo.categoryID;
		--local oldScript = self.SearchBox:GetScript("OnTextChanged");
		--self.SearchBox:SetScript("OnTextChanged", nil);
		--self.SearchBox:SetText(activityInfo.fullName);
		--self.SearchBox:SetScript("OnTextChanged", oldScript);
		LFGListDropDown_UpdateText(activity, activityInfo.fullName);
		C_LFGList.SetSearchToActivity(activity);
		C_LFGList.Search(self.categoryID, 0, 0, languages);
		--print("2")
	end

	self.searching = true;
	self.searchFailed = false;
	self.selectedResult = nil;
	MyLFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);

	-- If auto-create is desired, then the caller needs to set up that data after the search begins.
	-- There's an issue with using OnTextChanged to handle this due to how OnShow processes the update.
	if self.previousSearchText ~= searchText then
		LFGListEntryCreation_ClearAutoCreateMode(self:GetParent().EntryCreation);
	end

	self.previousSearchText = searchText;
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

local function GetPlaystyleString2(playstyle, activityInfo)
    local categoryInfo = C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID);
    if not categoryInfo.showPlaystyleDropdown then
        return
    end
    if activityInfo.isMythicPlusActivity then
        return _G["GROUP_FINDER_PVE_PLAYSTYLE"..playstyle]
    end
    if activityInfo.isCurrentRaidActivity then
        return _G["GROUP_FINDER_PVE_RAID_PLAYSTYLE"..playstyle]
    end
    if activityInfo.isMythicActivity then
        return _G["GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"..playstyle]
    end
    if activityInfo.isRatedPvpActivity then
    --if activityInfo.isRatedPvpActivity or activityInfo.isPvpActivity then
        return _G["GROUP_FINDER_PVP_PLAYSTYLE"..playstyle]
    end
    return "Unknown playstyle"
end

function MyLFGListUtil_SetSearchEntryTooltip(tooltip, resultID, autoAcceptOption)
	--print("MyLFGListUtil_SetSearchEntryTooltip", resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	local activityInfo = C_LFGList.GetActivityInfoTable(searchResultInfo.activityID, nil, searchResultInfo.isWarMode);

	local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID);
	tooltip:SetText(searchResultInfo.name, 1, 1, 1, true);
	--tooltip:AddLine(activityName);

	if (searchResultInfo.playstyle > 0) then
        local playstyleString = GetPlaystyleString2(searchResultInfo.playstyle, activityInfo);
		--print(searchResultInfo.playstyle, playstyleString);
		if playstyleString then
			if(not searchResultInfo.crossFactionListing) then 
				GameTooltip_AddColoredLine(tooltip, GROUP_FINDER_CROSS_FACTION_LISTING_WITH_PLAYSTLE:format(playstyleString,  FACTION_STRINGS[searchResultInfo.leaderFactionGroup]), GREEN_FONT_COLOR);
			else 
				GameTooltip_AddColoredLine(tooltip, playstyleString, GREEN_FONT_COLOR); 
			end 
		end
	elseif(not searchResultInfo.crossFactionListing) then 
		GameTooltip_AddColoredLine(tooltip, GROUP_FINDER_CROSS_FACTION_LISTING_WITHOUT_PLAYSTLE:format(FACTION_STRINGS[searchResultInfo.leaderFactionGroup]), GREEN_FONT_COLOR);
	end
	if ( searchResultInfo.comment and searchResultInfo.comment == "" and searchResultInfo.questID ) then
		searchResultInfo.comment = LFGListUtil_GetQuestDescription(searchResultInfo.questID);
	end
	if ( searchResultInfo.comment ~= "" ) then
		tooltip:AddLine(string.format(LFG_LIST_COMMENT_FORMAT, searchResultInfo.comment), LFG_LIST_COMMENT_FONT_COLOR.r, LFG_LIST_COMMENT_FONT_COLOR.g, LFG_LIST_COMMENT_FONT_COLOR.b, true);
	end
	tooltip:AddLine(" ");
	if ( searchResultInfo.requiredDungeonScore > 0 ) then
		tooltip:AddLine(GROUP_FINDER_MYTHIC_RATING_REQ_TOOLTIP:format(searchResultInfo.requiredDungeonScore));
	end
	if ( searchResultInfo.requiredPvpRating > 0 ) then
		tooltip:AddLine(GROUP_FINDER_PVP_RATING_REQ_TOOLTIP:format(searchResultInfo.requiredPvpRating));
	end
	if ( searchResultInfo.requiredItemLevel > 0 ) then
		if(activityInfo.isPvpActivity) then 
			tooltip:AddLine(LFG_LIST_TOOLTIP_ILVL_PVP:format(searchResultInfo.requiredItemLevel));
		else 
			tooltip:AddLine(LFG_LIST_TOOLTIP_ILVL:format(searchResultInfo.requiredItemLevel));
		end 
	end
	if ( activityInfo.useHonorLevel and searchResultInfo.requiredHonorLevel > 0 ) then
		tooltip:AddLine(LFG_LIST_TOOLTIP_HONOR_LEVEL:format(searchResultInfo.requiredHonorLevel));
	end
	if ( searchResultInfo.voiceChat ~= "" ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_VOICE_CHAT, searchResultInfo.voiceChat), nil, nil, nil, true);
	end
	if ( searchResultInfo.requiredItemLevel > 0 or (activityInfo.useHonorLevel and searchResultInfo.requiredHonorLevel > 0) or searchResultInfo.voiceChat ~= "" or  searchResultInfo.requiredDungeonScore > 0 or searchResultInfo.requiredPvpRating > 0 ) then
		tooltip:AddLine(" ");
	end

	if ( searchResultInfo.leaderName ) then
		if(searchResultInfo.leaderFactionGroup and (UnitFactionGroup("player") ~= PLAYER_FACTION_GROUP[searchResultInfo.leaderFactionGroup])) then 
			local factionString = FACTION_STRINGS[searchResultInfo.leaderFactionGroup]; 
			tooltip:AddLine(LFG_LIST_TOOLTIP_LEADER_FACTION:format(searchResultInfo.leaderName, factionString))
		else
			tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_LEADER, searchResultInfo.leaderName));
		end
	end

	if( activityInfo.isRatedPvpActivity and searchResultInfo.leaderPvpRatingInfo) then
		GameTooltip_AddNormalLine(tooltip, PVP_RATING_GROUP_FINDER:format(searchResultInfo.leaderPvpRatingInfo.activityName, searchResultInfo.leaderPvpRatingInfo.rating, PVPUtil.GetTierName(searchResultInfo.leaderPvpRatingInfo.tier)));
	elseif ( isMythicPlusActivity and searchResultInfo.leaderOverallDungeonScore) then 
		local color = C_ChallengeMode.GetDungeonScoreRarityColor(searchResultInfo.leaderOverallDungeonScore);
		if(not color) then 
			color = HIGHLIGHT_FONT_COLOR; 
		end 
		GameTooltip_AddNormalLine(tooltip, DUNGEON_SCORE_LEADER:format(color:WrapTextInColorCode(searchResultInfo.leaderOverallDungeonScore)));	
	end 

	if(activityInfo.isMythicPlusActivity and searchResultInfo.leaderDungeonScoreInfo) then 
		local leaderDungeonScoreInfo = searchResultInfo.leaderDungeonScoreInfo; 
		local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(leaderDungeonScoreInfo.mapScore);
		if (not color) then 
			color = HIGHLIGHT_FONT_COLOR;
		end 
		if(leaderDungeonScoreInfo.mapScore == 0) then 
			GameTooltip_AddNormalLine(tooltip, DUNGEON_SCORE_PER_DUNGEON_NO_RATING:format(leaderDungeonScoreInfo.mapName, leaderDungeonScoreInfo.mapScore));
		elseif (leaderDungeonScoreInfo.finishedSuccess) then 
			GameTooltip_AddNormalLine(tooltip, DUNGEON_SCORE_DUNGEON_RATING:format(leaderDungeonScoreInfo.mapName, color:WrapTextInColorCode(leaderDungeonScoreInfo.mapScore), leaderDungeonScoreInfo.bestRunLevel));
		else 
			GameTooltip_AddNormalLine(tooltip, DUNGEON_SCORE_DUNGEON_RATING_OVERTIME:format(leaderDungeonScoreInfo.mapName, color:WrapTextInColorCode(leaderDungeonScoreInfo.mapScore), leaderDungeonScoreInfo.bestRunLevel));
		end 	
	end
	if ( searchResultInfo.age > 0 ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_AGE, SecondsToTime(searchResultInfo.age, false, false, 1, false)));
	end

	if ( searchResultInfo.leaderName or searchResultInfo.age > 0 ) then
		tooltip:AddLine(" ");
	end

	if ( LFRAdvancedOptions.ShowMemberInfo ) then
		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_MEMBERS, searchResultInfo.numMembers, memberCounts.TANK, memberCounts.HEALER, memberCounts.DAMAGER));
		--local roleClasses = {};
		for i=1, searchResultInfo.numMembers do
			local role, class, classLocalized, specLocalized = C_LFGList.GetSearchResultMemberInfo(resultID, i);
			local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
			tooltip:AddLine(string.format("%s (%s) - %s", classLocalized, specLocalized, _G[role]), classColor.r, classColor.g, classColor.b);
			--local classcounts = roleClasses[role] or {};
			--roleClasses[role] = classcounts;
			--if not classcounts[class] then
			--	classcounts[class] = 1;
			--else
			--	classcounts[class] = classcounts[class] + 1;
			--end
		end
		--table.sort(roleClasses, function(a,b) return a > b end)
		--for role, classcnts in pairs(roleClasses) do
		--	--tooltip:AddLine(_G[role]..":");
		--	for class, cnt in pairs(classcnts) do
		--		local classColor = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR;
		--		tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_CLASS_ROLE.." - %d", LOCALIZED_CLASS_NAMES_MALE[class], _G[role], cnt), classColor.r, classColor.g, classColor.b);
		--	end
		--	table.wipe(classcnts);
		--end
		--table.wipe(roleClasses);
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

--hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", MyLFGListUtil_SetSearchEntryTooltip);
LFGListUtil_SetSearchEntryTooltip = MyLFGListUtil_SetSearchEntryTooltip;

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

local curveAchievementId = 14460;
local _, achievementTitle = GetAchievementInfo(curveAchievementId);
local achievementLink = GetAchievementLink(curveAchievementId);
local achievementLinkTemplate = "Link '%s' Achievement to leader";
local achievementActivityEnabled = {
	[720] = true,
	[721] = true,
	[722] = true,
}

local function LinkAchievement(_, name)
	if not name then return end

	if achievementLink then
		SendChatMessage(achievementLink, "WHISPER", nil, name);
		--print(achievementLink)
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

	local index = 3;
	local achLinkEnabled = achievementActivityEnabled[searchResultInfo.activityID];

	if achLinkEnabled then
		-- Link Achievement
		index = index + 1;
		retVal[index] = {};
		retVal[index].text = achievementLinkTemplate:format(achievementTitle);
		retVal[index].func = LinkAchievement;
		retVal[index].arg1 = searchResultInfo.leaderName;
		retVal[index].disabled = not searchResultInfo.leaderName or not achLinkEnabled;
		retVal[index].notCheckable = true;
	end

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

	if not achLinkEnabled then
		retVal[index + 1] = nil;
	end

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
