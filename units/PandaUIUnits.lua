PandaUIUnits = {}

local ClassDefaults = {
  DRUID = {
    allies = {
      base = {
        none = {"Regrowth"}
      },
      specs = {
        {
          none = {nil, "Remove Corruption"}
        },
        {
          none = {nil, "Remove Corruption"}
        },
        {
          none = {nil, "Remove Corruption"}
        },
        {
          none = {nil, "Rejuvenation", "Lifebloom"},
          shift = {"Nature's Grace"}
        }
      }
    },
    enemies = {
      base = {
        none = {"Entangling Roots", "Growl"}
      }
    }
  }
}

function PandaUIUnits:Initialize()
  if not PandaUISavedVariables.UnitFrames then
    PandaUISavedVariables.UnitFrames = {
      Target = {},
      Party = {},
      Player = {}
    }
  end
  if
    not PandaUISavedCharacterVariables.UnitFrames or
      not PandaUISavedCharacterVariables.UnitFrames.actions
   then
    PandaUISavedCharacterVariables.UnitFrames = {
      actions = ClassDefaults[UnitClassBase("player")]
    }
  end

  local root =
    PandaUICore:CreateFrame(
    "PandaUIUnits",
    {},
    {
      PandaUICore:Merge(
        PandaUIUnits:TargetFrame(
          PandaUISavedVariables.UnitFrames,
          PandaUISavedCharacterVariables.UnitFrames
        ),
        {ref = "targetFrame"}
      ),
      PandaUICore:Merge(
        PandaUIUnits:PlayerFrame(
          PandaUISavedVariables.UnitFrames,
          PandaUISavedCharacterVariables.UnitFrames
        ),
        {ref = "playerFrame"}
      )
    }
  )

  root:UpdateStyles()
  root:UpdateLayout()
  root:Init()

  -- control action setting at top level to be consistent about update behavior
  local actions = PandaUISavedCharacterVariables.UnitFrames.actions
  root.refs.targetFrame:SetActions(actions.enemies)
  root.refs.playerFrame:SetActions(actions.allies)
end

function PandaUIUnits:GetAction(actions, spec, mods, button)
  local action = nil
  if
    actions.base and actions.base[mods] and actions.base[mods][button]
   then
    action = actions.base[mods][button]
  end

  if
    actions.specs and actions.specs[spec] and
      actions.specs[spec][mods] and
      actions.specs[spec][mods][button]
   then
    action = actions.specs[spec][mods][button]
  end

  return action or ""
end
