PandaUIPlayer = {};

function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150)
        -- backgroundColor = {r = 0, g = 0, b = 1, a = 1}
    });

    self.healthBar = PandaUICore:CreateFrame("PlayerHealth", {
        parent = self.root,
        width = PandaUICore:pct(50),
        backgroundColor = {r = 0, g = 1, b = 0, a = 1}
    })

    self.primaryResourceBar = PandaUICore:CreateFrame("PrimaryResourceBar", {
        parent = self.root,
        width = PandaUICore:pct(50),
        backgroundColor = {r = 0, g = 0, b = 1, a = 1},
        anchor = PandaUICore:anchor("BOTTOMRIGHT")
    })
end
