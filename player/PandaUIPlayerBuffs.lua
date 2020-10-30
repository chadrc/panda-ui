local CellWidth = 40;
local CellHeight = 40;
local CellPadding = 5;
local Rows = 4;

local function MakeGrid(name, maxCount, anchor, filter)
    local items = {};
    for i = 1, maxCount do
        table.insert(items, {
            name = name .. i,
            height = PandaUICore:val(CellHeight),
            width = PandaUICore:val(CellWidth)
            -- backgroundColor = {r = 0.02 * i, g = 0, b = 0}
        })
    end

    local function Update(frame)
        local index = 1;
        AuraUtil.ForEachAura("player", filter, maxCount, function(...)
            local _, buffTexture, count, debuffType, duration, expirationTime,
                  _, _, _, _, _, _, _, _, timeMod = ...;
            local buffFrame = frame.childFrames[index];
            buffFrame.details.hidden = false;

            local texture = buffFrame:CreateTexture(
                                buffFrame:GetName() .. "Texture");
            texture:SetTexture(buffTexture);
            texture:SetSize(buffFrame:GetWidth(), buffFrame:GetHeight());
            texture:SetPoint("CENTER");

            buffFrame:UpdateStyles();

            index = index + 1;
            return index > maxCount;
        end);

        -- hide remaining frames
        for i = index, maxCount do
            frame.childFrames[i].details.hidden = true;
            frame.childFrames[i]:UpdateStyles();
        end
    end

    local grid = {
        name = name or "Grid",
        anchor = PandaUICore:anchor(anchor),
        children = items,
        layout = {parts = 5},
        backgroundColor = {r = 0, g = .5, b = .5},
        childLayout = {
            type = "grid",
            rows = Rows,
            cellWidth = CellWidth,
            cellHeight = CellHeight,
            cellPadding = CellPadding,
            start = anchor
        },
        events = {
            UNIT_AURA = function(frame, unit)
                if unit == "player" then Update(frame) end
            end,
            PLAYER_SPECIALIZATION_CHANGED = Update,
            PLAYER_ENTERING_WORLD = Update,
            GROUP_ROSTER_UPDATE = Update
        }
    };
    return grid;
end

function PandaUIPlayer:BuffsHeight()
    return CellHeight * Rows + (CellPadding * (Rows - 1));
end

function PandaUIPlayer:PlayerBuffs()
    return MakeGrid("Buffs", BUFF_MAX_DISPLAY, "TOPRIGHT", "HELPFUL");
end

function PandaUIPlayer:PlayerDebuffs()
    return MakeGrid("Debuggs", DEBUFF_MAX_DISPLAY, "TOPLEFT", "HARMFUL");
end
