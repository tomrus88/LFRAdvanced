function LFGListSearchPanel_DoSearch(self)
	--print("LFGListSearchPanel_DoSearch!");

	local activity = LFGListDropDown.activeValue or 0;

	if activity == 0 then
		-- Blizzard default code
		local searchText = self.SearchBox:GetText();
		C_LFGList.Search(self.categoryID, searchText, self.filters, self.preferredFilters);
	else
		local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activity);
		self.categoryID = categoryID;
		C_LFGList.Search(categoryID, fullName, 0, 0);
	end

	self.searching = true;
	self.searchFailed = false;
	self.selectedResult = nil;
	LFGListSearchPanel_UpdateResultList(self);
	LFGListSearchPanel_UpdateResults(self);
end

function LFGListSearchPanel_UpdateResultList(self)
	--print("LFGListSearchPanel_UpdateResultList");
	local searchText = self.SearchBox:GetText();
	if searchText ~= "" then
		--print("SearchText: "..searchText);

		self.totalResults, self.results = C_LFGList.GetSearchResults();

		local numResults = 0;
		local newResults = {};

		for i=1, #self.results do
			local matches = false;

			local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted = C_LFGList.GetSearchResultInfo(self.results[i]);
			local activityName = C_LFGList.GetActivityInfo(activityID);
			--print(id.." : "..name.. " : "..comment)
			local actvMatch = activityName:lower():find(searchText:lower());
			local nameMatch = name:lower():find(searchText:lower());
			local commMatch = comment:lower():find(searchText:lower());
			local matches = actvMatch or nameMatch or commMatch;
			if matches then
				numResults = numResults + 1
				newResults[numResults] = self.results[i];
			end
		end

		self.totalResults = numResults;
		self.results = newResults;
	else
		self.totalResults, self.results = C_LFGList.GetSearchResults();
		self.applications = C_LFGList.GetApplications();
		LFGListUtil_SortSearchResults(self.results);
	end
end

-- disable autocomplete
function LFGListSearchPanel_UpdateAutoComplete(self)
	self.AutoCompleteFrame:Hide();
	self.AutoCompleteFrame.selected = nil;
end
