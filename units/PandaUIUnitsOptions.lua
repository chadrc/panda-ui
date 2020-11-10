function PandaUIUnits:OptionsFrame()
  return {
    name = "OptionsFrame",
    ref = "optionsFrame",
    backgroundColor = {a = .5},
    height = PandaUICore:val(500),
    width = PandaUICore:val(500),
    anchor = PandaUICore:anchor("CENTER"),
    topLevel = true,
    frameStrata = "HIGH",
    hidden = true
  }
end
