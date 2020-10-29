function PandaUIPlayer:PlayerExpBar()
    local function Update(frame)
        if IsPlayerAtEffectiveMaxLevel() then
            frame.details.hidden = true;
            frame:GetParent():UpdateLayout();
            return;
        end

        local current = UnitXP("player");
        local max = UnitXPMax("player");

        frame:SetMinMaxValues(0, max);
        frame:SetValue(current);
    end

    return PandaUICore:StatusBar({
        name = "ExpBar",
        init = function(frame) Update(frame); end,
        events = {PLAYER_ENTERING_WORLD = Update, PLAYER_XP_UPDATE = Update}
    });
end
