PandaUIUnits = {}

local function MakeActionDefaults()
  return {
    helpful = {
      base = {}
    },
    harmful = {
      base = {}
    }
  }
end

local ClassDefaults = {
  DRUID = {
    helpful = {
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
    harmful = {
      base = {
        none = {"Entangling Roots", "Growl"}
      }
    }
  }
}

function PandaUIUnits:GetName()
  return "Units"
end

function PandaUIUnits:Initialize(accountData, characterData)
  if not accountData.frames then
    accountData.frames = {
      Target = {},
      Party = {},
      Player = {}
    }
  end

  if not characterData.actions then
    characterData.actions =
      ClassDefaults[UnitClassBase("player")] or MakeActionDefaults()
  end

  -- For testing
  characterData.actions =
    ClassDefaults[UnitClassBase("player")] or MakeActionDefaults()

  local root =
    PandaUICore:CreateFrame(
    "PandaUIUnits",
    {},
    {
      PandaUICore:Merge(
        PandaUIUnits:TargetFrame(accountData.frames.Target),
        {ref = "targetFrame"}
      ),
      PandaUICore:Merge(
        PandaUIUnits:PlayerFrame(accountData.frames.Player),
        {ref = "playerFrame"}
      ),
      PandaUIUnits:OptionsFrame()
    }
  )

  root:UpdateStyles()
  root:UpdateLayout()
  root:Init()

  self.root = root

  -- control action setting at top level to be consistent about update behavior
  local actions = PandaUISavedCharacterVariables.UnitFrames.actions
  root.refs.targetFrame:SetActions(actions)
  root.refs.playerFrame:SetActions(actions)
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

function PandaUIUnits:ShowOptions()
  self.root.refs.optionsFrame.details.hidden =
    not self.root.refs.optionsFrame.details.hidden
  self.root.refs.optionsFrame:UpdateStyles()
end

local function SlashAction(args)
  if args[2] == "options" then
    PandaUIUnits:ShowOptions()
  else
    return false, "Unknown Unit command " .. tostring(args[2])
  end

  return true, nil
end

function PandaUIUnits:GetSlashDetails()
  return {
    subCmd = "units",
    action = SlashAction
  }
end

PandaUICore:RegisterModule(PandaUIUnits)
