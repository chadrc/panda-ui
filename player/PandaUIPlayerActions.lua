local ButtonWidth = 40;
local ButtonHeight = 40;
local CellPadding = 5;
local Columns = 3;
local GridWidth = ButtonWidth * Columns + CellPadding * (Columns - 1);

local OffsetsByBar = {
    MultiBarRightButton = 24,
    MultiBarLeftButton = 36,
    MultiBarBottomRightButton = 48,
    MultiBarBottomLeftButton = 60
};

local ModifierToActionBar = {
    {mods = {"alt", "shift"}, bar = "MultiBarRightButton"},
    {mods = {"shift"}, bar = "MultiBarBottomLeftButton"},
    {mods = {"alt"}, bar = "MultiBarBottomRightButton"},
    {mods = {"ctrl"}, bar = "MultiBarLeftButton"}
};

function PandaUIPlayer:Actions()
    local buttons = {};
    for i = 1, 12 do
        table.insert(buttons, {
            name = "ActionButton" .. i,
            -- backgroundColor = {r = 0, g = 0, b = 1},
            children = {
                {name = "Icon", ref = "icon", texture = {}}, {
                    name = "BindingText",
                    text = {
                        font = "GameFontNormal",
                        anchor = PandaUICore:anchor("BOTTOM")
                    }
                }
            },
            init = function(frame)
                local button = CreateFrame("Button",
                                           frame:GetName() .. "Button", frame,
                                           "SecureActionButtonTemplate");

                frame.actionButton = button;

                local modTexts = {};
                for _, mod in ipairs(ModifierToActionBar) do
                    local mods = table.concat(mod.mods, "");
                    table.insert(modTexts, string.format("[mod:%s]%s%s", mods,
                                                         mod.bar, i));
                end

                local macroText = string.format("/click %s;ActionButton%s",
                                                table.concat(modTexts, ";"), i);

                button:SetSize(frame:GetWidth(), frame:GetHeight());
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", macroText);
                button:SetPoint("CENTER");
            end
        })
    end

    local function GetActionOffset(frame)
        local indexOffset = 0;
        if frame.bar > 0 then
            indexOffset = OffsetsByBar[ModifierToActionBar[frame.bar].bar];
        end

        -- check for bonus offset
        -- only main bar is changed to bonus
        local bonus = GetBonusBarOffset();
        if indexOffset == 0 and bonus > 0 then
            indexOffset = (NUM_ACTIONBAR_PAGES + bonus - 1) *
                              NUM_ACTIONBAR_BUTTONS;
        end

        return indexOffset;
    end

    local function UpdateActionButtons(frame)
        local indexOffset = GetActionOffset(frame);
        for i, childFrame in ipairs(frame.childFrames) do
            local actionIndex = i + indexOffset;
            local usable = IsUsableAction(actionIndex);
            local inRange = IsActionInRange(actionIndex);
            local hasTarget = UnitExists("target");

            if usable and inRange or not hasTarget then
                childFrame.refs.icon.details.alpha = 1.0;
            else
                childFrame.refs.icon.details.alpha = .25;
            end

            childFrame.refs.icon:UpdateStyles();
        end
    end

    local function SetupActionButtons(frame)
        local indexOffset = GetActionOffset(frame);
        for i, childFrame in ipairs(frame.childFrames) do
            local actionIndex = i + indexOffset;
            local texture = GetActionTexture(actionIndex);
            childFrame.refs.icon.details.texture.file = texture;
            childFrame.refs.icon:UpdateStyles();
        end

        UpdateActionButtons(frame);
    end

    return {
        name = "Actions",
        -- backgroundColor = {r = 1.0, g = 0, b = 0},
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
                children = buttons,
                init = function(frame)
                    frame.bar = 0;
                    frame.mods = {
                        "", -- alt
                        "", -- ctrl
                        "" -- shift
                    }
                end,
                events = {
                    PLAYER_ENTERING_WORLD = SetupActionButtons,
                    UPDATE_SHAPESHIFT_FORM = SetupActionButtons,
                    PLAYER_SPECIALIZATION_CHANGED = SetupActionButtons,
                    ACTIONBAR_UPDATE_STATE = UpdateActionButtons,
                    PLAYER_TARGET_CHANGED = function(frame)
                        if UnitExists("target") and not frame.hasTarget then
                            -- new target register update event to watch range changes
                            frame.hasTarget = true;
                            frame:SetScript("OnUpdate", function(frame)
                                UpdateActionButtons(frame);
                            end)
                        elseif not UnitExists("target") then
                            -- de-targeted
                            frame.hasTarget = false;
                            frame:SetScript("OnUpdate", nil);
                        end
                        UpdateActionButtons(frame);
                    end,
                    MODIFIER_STATE_CHANGED = function(frame, key, pressed)
                        local function CheckMod(name, index)
                            if string.find(key, name) then
                                if pressed == 1 then
                                    frame.mods[index] = string.lower(name);
                                else
                                    frame.mods[index] = "";
                                end
                            end
                        end

                        -- update state with pressed/relased
                        CheckMod("ALT", 1);
                        CheckMod("CTRL", 2);
                        CheckMod("SHIFT", 3);

                        -- use state to determine current mod combination and bar to use
                        local modStr = table.concat(frame.mods, "");

                        if modStr == "" then
                            frame.bar = 0;
                        else
                            for i, v in ipairs(ModifierToActionBar) do
                                local s = table.concat(v.mods, "");
                                if modStr == s then
                                    -- Only change if registered combo
                                    frame.bar = i;
                                    break
                                end
                            end
                        end

                        SetupActionButtons(frame);
                    end
                }
            }
        }
    }
end
