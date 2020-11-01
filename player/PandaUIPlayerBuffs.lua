local IconWidth = 35;
local IconHeight = IconWidth;
local CellPadding = 5;
local TextHeight = 15;
local Rows = 4;
local CellWidth = IconWidth;
local CellHeight = IconHeight + TextHeight;

local function MakeFillOrder(maxCount)
    local order = {};
    local next = {1};
    local visited = {};
    local c = 0; -- to prevent infinite iteration

    while table.getn(next) > 0 do
        local n = next[1];
        table.insert(order, n);
        table.remove(next, 1);

        if n + Rows <= maxCount and not visited[(n + Rows) .. ""] then
            table.insert(next, n + Rows);
            visited[(n + Rows) .. ""] = true;
        end

        if n + 1 <= maxCount and not visited[(n + 1) .. ""] then
            table.insert(next, n + 1);
            visited[(n + 1) .. ""] = true;
        end

        -- safty check
        c = c + 1;
        if c > maxCount then break end
    end

    return order;
end

local function UpdateAura(frame)
    if not frame.expirationTime or frame.expirationTime == 0 then return end

    local remaining = frame.expirationTime - GetTime();
    local suffix = ' s';
    if remaining > 3600 then
        remaining = remaining / 3600;
        suffix = ' h';
    elseif remaining > 60 then
        remaining = remaining / 60;
        suffix = ' m';
    end

    frame.refs.timeText.details.text.text = math.ceil(remaining) .. suffix;
    frame.refs.timeText:UpdateStyles();
end

local function MakeGrid(name, maxCount, anchor, filter, tooltipAnchor)
    local items = {};
    for i = 1, maxCount do
        table.insert(items, {
            type = "Button",
            name = name .. i,
            height = PandaUICore:val(CellHeight),
            width = PandaUICore:val(CellWidth),
            -- backgroundColor = {r = 0.02 * i, g = 0, b = 0},
            children = {
                {
                    name = "TextureFrame",
                    ref = "textureFrame",
                    height = PandaUICore:val(IconHeight),
                    width = PandaUICore:pct(1),
                    anchor = PandaUICore:anchor("TOP"),
                    texture = {anchor = PandaUICore:anchor("CENTER")},
                    children = {
                        {
                            name = "StackText",
                            ref = "stackText",
                            height = PandaUICore:val(TextHeight),
                            width = PandaUICore:pct(1),
                            anchor = PandaUICore:anchor("BOTTOMRIGHT"),
                            text = {
                                anchor = PandaUICore:anchor("BOTTOMRIGHT",
                                                            "BOTTOMRIGHT", -2, 2),
                                hidden = true,
                                font = "NumberFontNormal"
                            }
                        }
                    }
                }, {
                    name = "Text",
                    ref = "timeText",
                    height = PandaUICore:val(TextHeight),
                    width = PandaUICore:pct(1),
                    anchor = PandaUICore:anchor("BOTTOM"),
                    text = {
                        anchor = PandaUICore:anchor("CENTER"),
                        hidden = true,
                        font = "GameFontNormalSmall"
                    }
                }
            },
            onEnter = function(frame)
                GameTooltip:SetOwner(frame, tooltipAnchor);
                GameTooltip:SetFrameLevel(frame:GetFrameLevel() + 2);
                GameTooltip:SetUnitAura("player", frame.auraIndex, filter);
                GameTooltip:Show();
            end,
            onLeave = function(frame) GameTooltip:Hide(); end,
            clicks = {"RightButtonUp"},
            onClick = function(frame, button)
                if InCombatLockdown() then return end
                CancelUnitBuff("player", frame.auraIndex, filter);
            end
        })
    end

    -- Pre calculate fill order
    local fillOrder = MakeFillOrder(maxCount);

    local function Update(frame)
        local index = 1;
        local auraInfos = {};
        AuraUtil.ForEachAura("player", filter, maxCount, function(...)
            local name, buffTexture, count, debuffType, duration,
                  expirationTime, _, _, _, _, _, _, _, _, timeMod = ...;

            table.insert(auraInfos, {
                name = name,
                id = index,
                texture = buffTexture,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                timeMod = timeMod
            });

            index = index + 1;
            return index > maxCount;
        end);

        -- hide remaining frames
        for i = index, maxCount do
            local frameIndex = fillOrder[i];
            frame.childFrames[frameIndex].details.hidden = true;
            frame.childFrames[frameIndex]:UpdateStyles();
            frame.childFrames[frameIndex]:SetScript("OnUpdate", nil);
        end

        table.sort(auraInfos, function(left, right)
            if left.duration == 0 then
                return false;
            elseif right.duration == 0 then
                return true;
            end
            return left.expirationTime < right.expirationTime;
        end)

        for i, aura in ipairs(auraInfos) do
            local frameIndex = fillOrder[i];
            local buffFrame = frame.childFrames[frameIndex];
            buffFrame.expirationTime = aura.expirationTime;
            buffFrame.details.hidden = false;
            buffFrame.auraIndex = aura.id;

            buffFrame.refs.textureFrame.texture:SetTexture(aura.texture);

            local timeText = buffFrame.refs.timeText.details.text;
            local stackText = buffFrame.refs.stackText.details.text;

            if aura.duration > 0 and aura.expirationTime then
                timeText.hidden = false;
                buffFrame:SetScript("OnUpdate", UpdateAura);
                UpdateAura(buffFrame)
            else
                timeText.hidden = true;
            end

            stackText.hidden = not aura.count or aura.count == 0;
            stackText.text = aura.count or "";

            buffFrame.refs.timeText:UpdateStyles();
            buffFrame.refs.stackText:UpdateStyles();
            buffFrame:UpdateStyles();
        end
    end

    local grid = {
        name = name or "Grid",
        anchor = PandaUICore:anchor(anchor),
        children = items,
        layout = {parts = 5},
        -- backgroundColor = {r = 0, g = .5, b = .5},
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
    return MakeGrid("Buffs", BUFF_MAX_DISPLAY, "TOPRIGHT", "HELPFUL",
                    "ANCHOR_TOPRIGHT");
end

function PandaUIPlayer:PlayerDebuffs()
    return MakeGrid("Debuffs", DEBUFF_MAX_DISPLAY, "TOPLEFT", "HARMFUL",
                    "ANCHOR_TOPLEFT");
end
