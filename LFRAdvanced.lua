local ADDON_NAME, ADDON_TABLE = ...;

if LFRAdvancedOptions == nil then
	LFRAdvancedOptions = {
		ServerSideFiltering = false,
		ShowMemberInfo = true,
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
	--LFRAdvancedOptions.ShowLockouts = LFRAdvancedOptionsFrameShowLockouts:GetChecked();
	--LFRAdvancedOptions.ShowOldRaids = LFRAdvancedOptionsFrameShowOldRaids:GetChecked();
	--LFRAdvancedOptions.ShowPartyInfo = LFRAdvancedOptionsFrameShowPartyInfo:GetChecked();
	--LFRAdvancedOptions.IgnoreLevelReq = LFRAdvancedOptionsFrameIgnoreLevelReq:GetChecked();
	--LFRAdvancedOptions.CreateRaid = LFRAdvancedOptionsFrameCreateRaid:GetChecked();
end

function RefreshLFRAOptions()
	LFRAdvancedOptionsFrameServerSideFiltering:SetChecked(LFRAdvancedOptions.ServerSideFiltering);
	LFRAdvancedOptionsFrameShowMemberInfo:SetChecked(LFRAdvancedOptions.ShowMemberInfo);
	--LFRAdvancedOptionsFrameShowLockouts:SetChecked(LFRAdvancedOptions.ShowLockouts);
	--LFRAdvancedOptionsFrameShowOldRaids:SetChecked(LFRAdvancedOptions.ShowOldRaids);
	--LFRAdvancedOptionsFrameShowPartyInfo:SetChecked(LFRAdvancedOptions.ShowPartyInfo);
	--LFRAdvancedOptionsFrameIgnoreLevelReq:SetChecked(LFRAdvancedOptions.IgnoreLevelReq);
	--LFRAdvancedOptionsFrameCreateRaid:SetChecked(LFRAdvancedOptions.CreateRaid);
end
