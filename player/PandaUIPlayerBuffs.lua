local CellWidth = 40;
local CellHeight = 40;
local CellPadding = 5;
local Rows = 4;

local function MakeGrid(name, count, anchor)
    local items = {};
    for i = 1, count do
        table.insert(items, {
            name = "Buff" .. i,
            height = PandaUICore:val(CellHeight),
            width = PandaUICore:val(CellWidth),
            backgroundColor = {r = 0.02 * i, g = 0, b = 0}
        })
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
        }
    };
    return grid;
end

function PandaUIPlayer:BuffsHeight()
    return CellHeight * Rows + (CellPadding * (Rows - 1));
end

function PandaUIPlayer:PlayerBuffs()
    return MakeGrid("Buffs", BUFF_MAX_DISPLAY, "TOPRIGHT");
end

function PandaUIPlayer:PlayerDebuffs()
    return MakeGrid("Debuggs", DEBUFF_MAX_DISPLAY, "TOPLEFT");
end
