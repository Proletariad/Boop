local NN,
---@type Boop
Boop = ...

local Player = Boop.ActorManager:Get('player')
local None = Boop.ActorManager:Get('none')

local Kick = Boop.SpellManager:GetSpell(1766)

local KickTarget = Boop.ActorManager:CreateCustomActor('kick', function()
  local target = nil

  local InterruptTime = math.random(20, 40)

  Boop.ActorManager:EnumEnemies(function(actor)
      if actor:IsDead() then
        return false
      end

      if actor:IsInterruptibleAt(InterruptTime) and Kick:IsInRange(actor) and Player:IsFacing(actor) then
        target = actor
        return true
      end

      return false
  end)

  if target == nil then
    target = None
  end

  return target
end)

---@alias Kick fun()

---@type Kick
function _Kick()
  if KickTarget:Exists() and not Player:IsCastingOrChanneling() and Kick:IsKnownAndUsable() then
    Kick:Cast(KickTarget)
  end
end

return _Kick