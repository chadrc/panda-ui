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

local function SetCommonDetails(self, d, p)
    self:SetParent(p);

    local width = p:GetWidth();
    local height = p:GetHeight();
    local anchor = PandaUICore:anchor();

    if not d.width or d.width.type ~= "auto" then
        local width = ExtractValue(d.width, width) or width;
        if width == 0 then width = 0.000001; end
        self:SetWidth(width);
    end

    if not d.height or d.height.type ~= "auto" then
        local height = ExtractValue(d.height, height) or height;
        if height == 0 then height = 0.000001; end
        self:SetHeight(height);
    end

    local anchor = d.anchor or anchor;
    self:ClearAllPoints();
    self:SetPoint(anchor.base, p, anchor.relative, anchor.offsetX,
                  anchor.offsetY);

    if d.hidden then
        self:Hide();
    else
        self:Show()
    end
end

function FrameMixin:UpdateStyles()
    local d = self.details;
    local p = d.parent;

    self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", tile = true});
    self:SetBackdropColor(0, 0, 0, 0);

    if d.backgroundColor then
        local c = d.backgroundColor;
        self:SetBackdropColor(c.r, c.g, c.b, c.a);
    end

    SetCommonDetails(self, d, p);

    if d.texture then
        if not self.texture then
            self.texture = self:CreateTexture(self:GetName() .. "Texture");
        end

        local file = d.texture.file or "Interface\\Buttons\\WHITE8X8";

        SetCommonDetails(self.texture, d.texture, self);
        self.texture:SetTexture(file);
    end

    if d.text then
        local layer = d.text.layer or "OVERLAY";
        local font = d.text.font or "GameFontNormal";
        if not self.text then
            self.text = self:CreateFontString(self:GetName() .. "Text", layer,
                                              font);
        end

        d.text.width = d.text.width or PandaUICore:auto();
        d.text.height = d.text.height or PandaUICore:auto();

        SetCommonDetails(self.text, d.text, self);
        self.text:SetText(d.text.text or "");
    end
end

local function LayoutChildGrid(self)
    local rows = self.details.childLayout.rows;
    local columns = self.details.childLayout.columns;
    local numChildren = table.getn(self.childFrames);
    if not rows and not columns then
        rows = 1;
        columns = numChildren;
    elseif not rows then
        rows = math.ceil(numChildren / columns);
    elseif not columns then
        columns = math.ceil(numChildren / rows);
    end
    local cellWidth = self.details.childLayout.cellWidth;
    local cellHeight = self.details.childLayout.cellHeight;
    local cellPadding = self.details.childLayout.cellPadding or 0;

    local totalHeight = cellWidth * rows;
    local totalWidth = cellHeight * columns;

    self.details.height = PandaUICore:val(totalHeight);
    self.details.width = PandaUICore:val(totalWidth);

    local start = self.details.childLayout.start or "BOTTOMLEFT";
    local xFactor = 1;
    local yFactor = 1;

    if start == "BOTTOMRIGHT" then
        xFactor = -1;
    elseif start == "TOPLEFT" then
        yFactor = -1;
    elseif start == "TOPRIGHT" then
        xFactor = -1;
        yFactor = -1;
    end

    for i, child in pairs(self.childFrames) do
        child.details.width = PandaUICore:val(cellWidth);
        child.details.height = PandaUICore:val(cellHeight);

        local index = i - 1;
        local col = math.floor(index / rows);
        local row = index % rows;
        local offsetX = col * (cellWidth + cellPadding) * xFactor;
        local offsetY = row * (cellHeight + cellPadding) * yFactor;

        child.details.anchor =
            PandaUICore:anchor(start, start, offsetX, offsetY);

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
