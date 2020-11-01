local ButtonWidth = 40;
local ButtonHeight = 40;
local CellPadding = 5;
local Columns = 3;
local GridWidth = ButtonWidth * Columns + CellPadding * (Columns - 1);

function PandaUIPlayer:Actions()
    local buttons = {};
    for i = 1, 12 do
        table.insert(buttons, {
            name = "ActionButton" .. i,
            backgroundColor = {r = 0, g = 0, b = 1},
            children = {
                {name = "Icon", texture = {}}, {
                    name = "BindingText",
                    text = {
                        font = "GameFontNormal",
                        anchor = PandaUICore:anchor("BOTTOM")
                    }
                }
                -- {
                --     name = "Button",
                --     type = "Button",
                --     clicks = {"LeftButton"},
                --     template = "SecureActionButtonTemplate",
                --     -- onClick = function(frame, button)
                --     --     print('click: ', button);
                --     -- end,
                --     -- attributes = {
                --     --     ["type*"] = "spell",
                --     --     ["spell*"] = "Regrowth",
                --     --     ["unit*"] = "player"
                --     -- },
                --     init = function(frame)
                --         frame:SetAttribute("type", "spell");
                --         frame:SetAttribute("spell", "Regrowth");
                --         frame:SetAttribute("unit", "player");
                --     end
                -- }
            },
            init = function(frame)
                local button = CreateFrame("Button",
                                           frame:GetName() .. "Button", frame,
                                           "SecureActionButtonTemplate");
                local macroText = string.format(
                                      "/click [mod:altshift]MultiBarRightButton%s;[mod:shift]MultiBarBottomLeftButton%s;[mod:alt]MultiBarBottomRightButton%s;[mod:ctrl]MultiBarLeftButton%s;ActionButton%s",
                                      i, i, i, i, i);
                -- button:SetID(1);
                button:SetSize(frame:GetWidth(), frame:GetHeight());
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", macroText);
                -- button:SetAttribute("shift-type", "action");
                -- button:SetAttribute("alt-type", "action");
                -- button:SetAttribute("alt-shift-type", "action");
                -- button:SetAttribute("ctrl-type", "action");

                -- button:SetAttribute("action", i);
                -- button:SetAttribute("shift-action", i + 12); -- bar 2
                -- button:SetAttribute("alt-shift-action", i + 24); -- bar 3
                -- button:SetAttribute("ctrl-action", i + 36); -- bar 4
                -- button:SetAttribute("shift-action", i + 48); -- bar 5
                -- button:SetAttribute("alt-action", i + 60); -- bar 6
                button:SetPoint("CENTER");
            end
        })
    end
    return {
        name = "Actions",
        backgroundColor = {r = 1.0, g = 0, b = 0},
        children = {
            {
                name = "Buttons",
                anchor = PandaUICore:anchor("TOP"),
                width = PandaUICore:val(GridWidth),
                childLayout = {
                    type = "grid",
                    columns = Columns,
                    cellWidth = ButtonWidth,
                    cellHeight = ButtonHeight,
                    cellPadding = CellPadding,
                    start = "TOPLEFT"
                },
                children = buttons
            }
        }
    }
end
