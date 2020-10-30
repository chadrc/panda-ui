function PandaUIPlayer:PlayerBuffs()
    local buffs = {};
    for i = 1, BUFF_MAX_DISPLAY do
        table.insert(buffs, {
            name = "Buff" .. i,
            height = PandaUICore:val(40),
            width = PandaUICore:val(40),
            backgroundColor = {r = 0.02 * i, g = 0, b = 0, a = .2}
        })
    end

    local buffInfo = {
        name = "Buffs",
        anchor = PandaUICore:anchor("TOP"),
        children = buffs,
        height = PandaUICore:val(150),
        width = PandaUICore:pct(1),
        backgroundColor = {r = 0, g = .5, b = .5},
        childLayout = {
            type = "grid",
            rows = 4,
            cellWidth = 40,
            cellHeight = 40,
            start = "TOPLEFT"
        }
    };
    return buffInfo;
end
