function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150 + self:BuffsHeight())
        -- for debuggging, remove for live
        -- backgroundColor = {r = .7, g = 0, b = 0, a = .2}
    }, {
        {
            name = "TopBar",
            height = PandaUICore:val(self:BuffsHeight()),
            anchor = PandaUICore:anchor("TOPLEFT"),
            childLayout = {direction = "horizontal"},
            children = {
                self:PlayerBuffs(), {name = "Actions"}, self:PlayerDebuffs()
            }
        }, {
            name = "PlayerInfo",
            height = PandaUICore:val(150),
            childLayout = {direction = "vertical"},
            backgroundColor = {r = 0, g = 0, b = 0, a = .5},
            children = {
                self:PlayerCastingBar(), {
                    layout = {parts = 6},
                    childLayout = {direction = "horizontal"},
                    children = {
                        self:PlayerHealthFrame(), self:PlayerPowerFrame()
                    }
                }, self:PlayerExpBar()
            }
        }
    });

    self.root:UpdateStyles();
    self.root:UpdateLayout();
    self.root:Init();
end
