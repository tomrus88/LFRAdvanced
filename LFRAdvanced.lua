function MyFunction(self, ...)
    local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isLeader, isTank, isHealer, isDamage, talentPoints, spec1, spec2, spec3, isLFM, Armor, SpellDamage, SpellHeal, CritMelee, CritRanged, CritSpell, MP5, MP5Combat, AttackPower, Agility, Health, Mana, Unk1, avgILVL, Unk2, Dodge, Block, Parry, Haste, Expertise = SearchLFGGetResults(self.index);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 27, -37);

    if ( partyMembers > 0 ) then
        GameTooltip:AddLine(LOOKING_FOR_RAID);

        GameTooltip:AddLine(name);
        GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0, 0.25, 0, 1);

        GameTooltip:AddLine(format(LFM_NUM_RAID_MEMBER_TEMPLATE, partyMembers));
        -- Bogus texture to fix spacing
        GameTooltip:AddTexture("");

        --Display party members.
        GameTooltip:AddLine("\n"..IMPORTANT_PEOPLE_IN_GROUP);
        for i=1, partyMembers do
            local name, level, relationship, className, areaName, comment = SearchLFGGetPartyResults(self.index, i);
            if ( relationship ) then
                if ( relationship == "ignored" ) then
                    GameTooltip:AddDoubleLine(name, IGNORED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
                elseif ( relationship == "friend" ) then
                    GameTooltip:AddDoubleLine(name, FRIEND, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                end
            else
                GameTooltip:AddDoubleLine(name, PLAYER, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
            end
        end
    else
        GameTooltip:AddLine(name);
        GameTooltip:AddLine(format(FRIENDS_LEVEL_TEMPLATE, level, className));
    end

    if ( comment and comment ~= "" ) then
        GameTooltip:AddLine("\n"..comment, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
    end

    if ( partyMembers == 0 ) then
        GameTooltip:AddLine("\n"..LFG_TOOLTIP_ROLES);
        if ( isTank ) then
            GameTooltip:AddLine(TANK);
            GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.5, 0.75, 0, 1);
        end
        if ( isHealer ) then
            GameTooltip:AddLine(HEALER);
            GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.75, 1, 0, 1);
        end
        if ( isDamage ) then
            GameTooltip:AddLine(DAMAGER);
            GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", 0.25, 0.5, 0, 1);
        end
    end

    if ( encountersComplete > 0 ) then
        GameTooltip:AddLine("\n"..BOSSES);
        for i=1, encountersTotal do
            local bossName, texture, isKilled = SearchLFGGetEncounterResults(self.index, i);
            if ( isKilled ) then
                GameTooltip:AddDoubleLine(bossName, BOSS_DEAD, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
            else
                GameTooltip:AddDoubleLine(bossName, BOSS_ALIVE, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
            end
        end
    elseif ( partyMembers > 0 and encountersTotal > 0) then
        GameTooltip:AddLine("\n"..ALL_BOSSES_ALIVE);
    end

    local classColor = RAID_CLASS_COLORS[class];

    -- Sometimes it's nil for no reason
    if ( not classColor ) then
        classColor = NORMAL_FONT_COLOR;
    end

    local classColorString = format("ff%.2x%.2x%.2x", classColor.r * 255, classColor.g * 255, classColor.b * 255);
    local spec = format("%u/%u/%u", spec1, spec2, spec3);

    GameTooltip:AddLine(format(PLAYER_LEVEL, level, classColorString, spec, className));

    GameTooltip:AddLine("Extra info:");

    if ( areaName ) then
        GameTooltip:AddLine(format("Zone: %s", areaName));
    end

    if ( talentPoints and talentPoints > 0 ) then
        GameTooltip:AddLine(format(UNSPENT_TALENT_POINTS, talentPoints));
    end

    if ( isLFM ) then
        GameTooltip:AddLine(format("LFM: %s", tostring(isLFM)));
    end

    if ( Armor and Armor > 0 ) then
        GameTooltip:AddLine(format(ARMOR_TEMPLATE, Armor));
    end

    if ( (SpellDamage and SpellDamage > 0) or (SpellHeal and SpellHeal > 0) ) then
        GameTooltip:AddLine(format("Spell power: %u (%u +heal)", SpellDamage, SpellHeal));
    end

    if ( (CritMelee and CritMelee > 0) or (CritRanged and CritRanged > 0) or (CritSpell and CritSpell > 0) ) then
        GameTooltip:AddLine(format("Crit rating: melee %u, ranged %u, spell %u", CritMelee, CritRanged, CritSpell));
    end

    if ( (MP5 and MP5 > 0) or (MP5Combat and MP5Combat > 0) ) then
        GameTooltip:AddLine(format("MP5: %u (in combat %u)", MP5, MP5Combat));
    end

    if ( AttackPower and AttackPower > 0 ) then
        GameTooltip:AddLine(format("Melee Attack Power: %u", AttackPower));
    end

    if ( Agility and Agility > 0 ) then
        GameTooltip:AddLine(format("Agility: %u", Agility));
    end

    if ( Health and Health > 0 ) then
        GameTooltip:AddLine(format(MAX_HP_TEMPLATE, Health));
    end

    if ( Mana and Mana > 0 ) then
        GameTooltip:AddLine(format("Mana: %u", Mana));
    end

    if ( Unk1 and Unk1 > 0 ) then
        GameTooltip:AddLine(format("Unknown1: %u", Unk1));
    end

    if ( avgILVL and avgILVL > 0 ) then
        GameTooltip:AddLine(format("Average Item level: %.02f", avgILVL));
    end

    if ( Unk2 and Unk2 > 0 ) then
        GameTooltip:AddLine(format("Unknown2: %u", Unk2));
    end

    if ( Dodge and Dodge > 0 ) then
        GameTooltip:AddLine(format("Dodge rating: %u", Dodge));
    end

    if ( Block and Block > 0 ) then
        GameTooltip:AddLine(format(SHIELD_BLOCK_TEMPLATE, Block));
    end

    if ( Parry and Parry > 0 ) then
        GameTooltip:AddLine(format("Parry rating: %u", Parry));
    end

    if ( Haste and Haste > 0 ) then
        GameTooltip:AddLine(format("Haste rating: %u", Haste));
    end

    if ( Expertise and Expertise > 0 ) then
        GameTooltip:AddLine(format("Expertise: %u", Expertise));
    end

    GameTooltip:Show();
end

for i=1, NUM_LFR_LIST_BUTTONS do
    local button = _G["LFRBrowseFrameListButton"..i];
    button:SetScript("OnEnter", MyFunction);
end
