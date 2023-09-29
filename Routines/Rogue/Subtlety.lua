local 
NN,
---@type Boop
Boop = ...

local ComboPoints = Enum.PowerType.ComboPoints
local Energy = Enum.PowerType.Energy

local SubtletyModule = Boop.Module:New('subtlety')

local Player = Boop.ActorManager:Get('player')
local Target = Boop.ActorManager:Get('target')
local None = Boop.ActorManager:Get('none')

local AutoAttack = Boop.SpellManager:GetSpell(6603)
local InstantPoison = Boop.SpellManager:GetSpell(315584)
local CripplingPoison = Boop.SpellManager:GetSpell(3408)
local SliceAndDice = Boop.SpellManager:GetSpell(315496)
local Eviscerate = Boop.SpellManager:GetSpell(196819)
local ShurikenStorm = Boop.SpellManager:GetSpell(197835)
local ShadowStrike = Boop.SpellManager:GetSpell(185438)
local CrimsonVial = Boop.SpellManager:GetSpell(185311)
local Gloomblade = Boop.SpellManager:GetSpell(200758)
local ShurikenToss = Boop.SpellManager:GetSpell(114014)
local BlackPowder = Boop.SpellManager:GetSpell(319175)
local ShadowDance = Boop.SpellManager:GetSpell(185422)
local SecretTechnique = Boop.SpellManager:GetSpell(280719)
local SymbolsOfDeath = Boop.SpellManager:GetSpell(212283)

---@type Kick
local Kick = Boop:Require("@Rogue/shared/Kick.lua")

local function DefensiveRotation()
  if Player:GetHealthPercent() < 40 and CrimsonVial:IsKnownAndUsable() then
    return CrimsonVial:Cast(Player)
  end
end

---@return boolean
local function CombatRotation()
  local NumEnemies = Player:GetEnemies(10)
  local isAoe = NumEnemies > 1
  local isBlackPowder = NumEnemies > 2
  local PlayerComboPoints = Player:GetPower(ComboPoints)
  local PlayerEnergy = Player:GetPower(Energy)
  local PlayerMaxEnegy = Player:GetMaxPower(Energy)
  local IsDance = Player:GetAuras():FindAny(ShadowDance):IsUp()
  local isStealthed = Player:IsStealthed()
  local isTargetValid = Target:Exists() and Target:IsAlive() and Target:IsEnemy()
  local PlayerAuras = Player:GetAuras()

  if not isStealthed and isTargetValid and AutoAttack:IsKnownAndUsable() and not IsCurrentSpell(AutoAttack:GetID()) and Player:InMelee(Target) and not Target:IsDead() then
    AutoAttack:Cast(Target)
  end

  Kick()

  if PlayerEnergy + 50 < PlayerMaxEnegy and SymbolsOfDeath:IsKnownAndUsable() and isTargetValid and Player:InMelee(Target) then
    SymbolsOfDeath:Cast(Player)
  end

  -- Cast SnD at 4+ CP
  if (not PlayerAuras:FindMy(SliceAndDice):IsUp() or PlayerAuras:FindMy(SliceAndDice):GetRemainingTime() < 6) and PlayerComboPoints >= 4 and SliceAndDice:IsKnownAndUsable() then
    return SliceAndDice:Cast(Player)
  end

  if isTargetValid and PlayerComboPoints > 5 and not isStealthed and SecretTechnique:IsKnownAndUsable() and SecretTechnique:IsInRange(Target) then
    return SecretTechnique:Cast(Target)
  end

  -- Cast Evis at 5 CP
  if not isStealthed and not isBlackPowder and isTargetValid and Eviscerate:IsKnownAndUsable() and PlayerComboPoints > 5 and Eviscerate:IsInRange(Target) then
    return Eviscerate:Cast(Target)
  end

  if not isStealthed and isBlackPowder and BlackPowder:IsKnownAndUsable() and PlayerComboPoints > 5 then
    return BlackPowder:Cast(Player)
  end

  -- SS as builder in ST
  if not isAoe and not isStealthed and isTargetValid and not IsDance and Gloomblade:IsKnownAndUsable() and Player:IsFacing(Target) and Gloomblade:IsInRange(Target) then
    return Gloomblade:Cast(Target)
  end

  -- Shuriken Storm as builder in AOE
  if isAoe and not isStealthed and ShurikenStorm:IsKnownAndUsable() then
    return ShurikenStorm:Cast(Player)
  end

  -- Shadowstrike as builder in stealth
  if (isStealthed or IsDance) and ShadowStrike:IsKnownAndUsable() and isTargetValid and Player:IsFacing(Target) and ShadowStrike:IsInRange(Target)  then
    return ShadowStrike:Cast(Target)
  end

  if not isStealthed and isTargetValid and ShurikenToss:IsKnownAndUsable() and Player:IsFacing(Target) and Player:GetDistance(Target) >= 25 then
    return ShurikenToss:Cast(Target)
  end

  return false
end


---@return boolean
local function OutOfCombatRotation()
  return false
end


local isRunning = false

SubtletyModule:Sync(function()
  if not isRunning then
    Boop:Print('Subtlety Started')
    isRunning = true
  end

  if Player == nil then return false end

  if not Player:IsAlive() or IsMounted() or Player:IsInVehicle() then
      return false
  end

  if Player:GetCastingOrChannelingSpell() ~= nil then
    return false
  end

  if not Player:IsMoving() and not Player:GetAuras():FindMy(InstantPoison):IsUp() then
    return InstantPoison:Cast(Player)
  end

  if not Player:IsMoving() and not Player:GetAuras():FindMy(CripplingPoison):IsUp() then
    return CripplingPoison:Cast(Player)
  end

  if DefensiveRotation() then return true end

  if Player:IsAffectingCombat() or IsCurrentSpell(AutoAttack:GetID()) then
      -- Combat Rotation
      return CombatRotation()
  else 
      -- Out Of Combat Rotation
      return OutOfCombatRotation()
  end
end)

Boop:Register(SubtletyModule)