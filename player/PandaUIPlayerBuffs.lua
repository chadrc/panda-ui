local IconWidth = 35;
local IconHeight = IconWidth;
local CellPadding = 5;
local TextHeight = 15;
local Rows = 4;
local CellWidth = IconWidth;
local CellHeight = IconHeight + TextHeight;

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

    frame.refs.timeText.text:SetText(math.ceil(remaining) .. suffix);
end

local function MakeGrid(name, maxCount, anchor, filter)
    local items = {};
    for i = 1, maxCount do
        table.insert(items, {
            name = name .. i,
            height = PandaUICore:val(CellHeight),
            width = PandaUICore:val(CellWidth),
            -- backgroundColor = {r = 0.02 * i, g = 0, b = 0},
            children = {
                {
                    name = "TextureFrame",
                    ref = "texture",
                    height = PandaUICore:val(IconHeight),
                    width = PandaUICore:pct(1),
                    anchor = PandaUICore:anchor("TOP"),
                    children = {
                        {
                            name = "StackText",
                            ref = "stackText",
                            height = PandaUICore:val(TextHeight),
                            width = PandaUICore:pct(1),
                            anchor = PandaUICore:anchor("BOTTOMRIGHT")
                        }
                    }
                }, {
                    name = "Text",
                    ref = "timeText",
                    height = PandaUICore:val(TextHeight),
                    width = PandaUICore:pct(1),
                    anchor = PandaUICore:anchor("BOTTOM")
                }
            }
        })
    end

    local function Update(frame)
        local index = 1;
        AuraUtil.ForEachAura("player", filter, maxCount, function(...)
            local name, buffTexture, count, debuffType, duration,
                  expirationTime, _, _, _, _, _, _, _, _, timeMod = ...;
            local buffFrame = frame.childFrames[index];
            buffFrame.expirationTime = expirationTime;
            buffFrame.details.hidden = false;

            local textureFrame = buffFrame.refs.texture;
            local texture = textureFrame.texture;
            if not texture then
                texture = textureFrame:CreateTexture(
                              textureFrame:GetName() .. "Texture");
                textureFrame.texture = texture;
            end

            local textFrame = buffFrame.refs.timeText;
            local text = textFrame.text;
            if not text then
                text = textFrame:CreateFontString(textFrame:GetName() .. "Text",
                                                  "OVERLAY",
                                                  "GameFontNormalSmall")
                textFrame.text = text;
            end

            local stackTextFrame = buffFrame.refs.stackText;
            local stackText = stackTextFrame.text;
            if not stackText then
                stackText = stackTextFrame:CreateFontString(
                                stackTextFrame:GetName() .. "Text", "OVERLAY",
                                "NumberFontNormal");
                stackTextFrame.text = stackText;
            end

            texture:SetTexture(buffTexture);
            texture:SetSize(textureFrame:GetWidth(), textureFrame:GetHeight());
            texture:SetPoint("CENTER");

            text:SetPoint("CENTER");

            if duration > 0 and expirationTime then
                text:Show();
                buffFrame:SetScript("OnUpdate", UpdateAura);
                UpdateAura(buffFrame)
            else
                text:Hide();
            end

            stackText:SetPoint("BOTTOMRIGHT", -2, 2);

            if not count or count == 0 then
                stackText:Hide();
            else
                stackText:Show();
                stackText:SetText(count);
            end

            textureFrame:UpdateStyles();
            textFrame:UpdateStyles();
            buffFrame:UpdateStyles();

            index = index + 1;
            return index > maxCount;
        end);

        -- hide remaining frames
        for i = index, maxCount do
            frame.childFrames[i].details.hidden = true;
            frame.childFrames[i]:UpdateStyles();
            frame.childFrames[i]:SetScript("OnUpdate", nil);
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
