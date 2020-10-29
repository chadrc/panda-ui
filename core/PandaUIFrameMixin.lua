local FrameMixin = {};

local function ExtractValue(info, parentValue)
    if info then
        if info.type == "percentage" then
            return parentValue * info.value;
        else
            return info.value
        end
    end
end

function FrameMixin:Init()
    if self.details.init then self.details.init(self); end
    for _, childFrame in pairs(self.childFrames) do childFrame:Init() end
end

function FrameMixin:UpdateStyles()
    local d = self.details;
    local p = d.parent;
    local width = p:GetWidth();
    local height = p:GetHeight();
    local anchor = PandaUICore:anchor();

    if d.hidden then
        self:Hide();
    else
        self:Show()
    end

    self:SetParent(p);
    self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", tile = true});
    self:SetBackdropColor(0, 0, 0, 0);

    if d.backgroundColor then
        local c = d.backgroundColor;
        self:SetBackdropColor(c.r, c.g, c.b, c.a);
    end

    width = ExtractValue(d.width, width) or width;
    height = ExtractValue(d.height, height) or height;
    anchor = d.anchor or anchor;

    -- Look for better solution
    if width == 0 then width = 0.000001; end
    if height == 0 then height = 0.000001; end

    self:SetSize(width, height);
    self:ClearAllPoints();
    self:SetPoint(anchor.base, p, anchor.relative, anchor.offsetX,
                  anchor.offsetY);
end

local function LayoutChildGrid(self)
    local rows = self.details.childLayout.rows;
    local columns = math.floor(table.getn(self.childFrames) / rows);
    local cellWidth = self.details.childLayout.cellWidth;
    local cellHeight = self.details.childLayout.cellHeight;

    local totalHeight = cellWidth * rows;
    local totalWidth = cellHeight * columns;

    self.details.height = PandaUICore:val(totalHeight);
    self.details.width = PandaUICore:val(totalWidth);

    self:UpdateStyles(); -- may need to remove if parent ever controls size

    local start = self.details.childLayout.start or "BOTTOMLEFT";
    local xFactor = 1;
    local yFactor = 1;
    local offX = 0;
    local offY = 0;

    if start == "BOTTOMRIGHT" then
        xFactor = -1;
        offX = cellWidth * (columns - 1);
    elseif start == "TOPLEFT" then
        yFactor = -1;
        offY = cellHeight * (rows - 1);
    elseif start == "TOPRIGHT" then
        xFactor = -1;
        yFactor = -1;
        offX = cellWidth * (columns - 1);
        offY = cellHeight * (rows - 1);
    end

    for i, child in pairs(self.childFrames) do
        child.details.width = PandaUICore:val(cellWidth);
        child.details.height = PandaUICore:val(cellHeight);

        local index = i - 1;
        local offsetX = math.floor(index / rows) * cellWidth * xFactor;
        local offsetY = (index % rows) * cellHeight * yFactor;

        child.details.anchor = PandaUICore:anchor("BOTTOMLEFT", "BOTTOMLEFT",
                                                  offsetX + offX, offsetY + offY);

        child:UpdateStyles();
        child:UpdateLayout();
    end
end

function FrameMixin:UpdateLayout()
    local totalParts = 0;
    local childLayout = self.details.childLayout or {};

    -- pre calculate parts
    for i, childFrame in ipairs(self.childFrames) do
        local child = childFrame.details;
        local childParts = 0;

        if child.layout then
            childParts = child.layout.parts or 1;
            child.layout.parts = childParts;
        else
            childParts = 1;
            child.layout = {parts = childParts}
        end

        -- ignore hidden elements
        if not child.hidden then totalParts = totalParts + childParts; end
    end

    if childLayout.type == "grid" then
        LayoutChildGrid(self);
    else
        local currentChildOffsetX = 0;
        local currentChildOffsetY = 0;
        for i, child in pairs(self.childFrames) do
            -- layout children according to options
            if childLayout.direction == "horizontal" then
                -- horizontal children have same height as parent
                -- calculate width based on parts
                child.details.height = PandaUICore:val(self:GetHeight());

                local childWidth = self:GetWidth() *
                                       (child.details.layout.parts / totalParts);
                child.details.width = PandaUICore:val(childWidth);
                child.details.anchor = PandaUICore:anchor("BOTTOMLEFT", nil,
                                                          currentChildOffsetX, 0);

                if not child.details.hidden then
                    currentChildOffsetX = currentChildOffsetX + childWidth;
                end
            elseif childLayout.direction == "vertical" then
                -- vertical children have same width as parent
                -- calculate height based on parts
                child.details.width = PandaUICore:val(self:GetWidth());

                local childHeight = self:GetHeight() *
                                        (child.details.layout.parts / totalParts);
                child.details.height = PandaUICore:val(childHeight);
                child.details.anchor = PandaUICore:anchor("TOPLEFT", nil, 0,
                                                          -currentChildOffsetY);

                if not child.details.hidden then
                    currentChildOffsetY = currentChildOffsetY + childHeight;
                end
            end

            child:UpdateStyles();
            child:UpdateLayout();
        end
    end
end

function PandaUICore:ApplyFrameMixin(to)
    for k, v in pairs(FrameMixin) do to[k] = v end
end