local NN,
---@type Boop
Boop = ...

-- Create a new Spell class
---@class Spell
---@field spellID number
---@field PostCastFunc boolean | fun(self:Spell)
---@field OnCastFunc boolean | fun(self:Spell)
---@field PreCastFunc boolean | fun(self:Spell)
---@field lastCastAttempt nil | number
---@field lastCastAt nil | number
---@field target nil | Actor
---@field wasLooking boolean
local Spell = {
    PostCastFunc = false,
    CastableIfFunc = false,
    OnCastFunc = false,
    PreCastFunc = false,
    wasLooking = false
}

Spell.__index = Spell

-- Equals
---@param other Spell
---@return boolean
function Spell:__eq(other)
    return self:GetID() == other:GetID()
end

-- tostring
---@return string
function Spell:__tostring()
    return "Boop.__Spell(" .. self:GetID() .. ")" .. " - " .. self:GetName()
end

-- Constructor
---@param id number
---@return Spell
function Spell:New(id)
    local self = setmetatable({}, Spell)

    self.spellID = id

    return self
end

-- Get the spells id
---@return number
function Spell:GetID()
    return self.spellID
end

-- Add post cast func
---@param func fun(self:Spell)
---@return Spell
function Spell:PostCast(func)
    self.PostCastFunc = func
    return self
end

-- Get the spells name
---@return string
function Spell:GetName()
    local info = GetSpellInfo(self:GetID())
    return info
end

-- Get the spells icon
---@return number
function Spell:GetIcon()
    return select(3, GetSpellInfo(self:GetID()))
end

-- Get the spells cooldown
---@return number
function Spell:GetCooldown()
    return select(2, GetSpellCooldown(self:GetID()))
end

-- Get the full cooldown (time until all charges are available)
---@return number
function Spell:GetFullRechargeTime()
    local start, duration, enabled = GetSpellCooldown(self:GetID())
    if enabled == 0 then
        return 0
    end

    local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(self:GetID())
    if charges == maxCharges then
        return 0
    end

    if charges == 0 then
        return start + duration - GetTime()
    end

    return chargeStart + chargeDuration - GetTime()
end

-- Return the castable function
---@return boolean | fun(self:Spell):boolean
function Spell:GetCastableFunction()
    return self.CastableIfFunc
end

-- Return the precast function
---@return boolean | fun(self:Spell)
function Spell:GetPreCastFunction()
    return self.PreCastFunc
end

-- Get the on cast func
---@return boolean | fun(self:Spell)
function Spell:GetOnCastFunction()
    return self.OnCastFunc
end

-- Get the spells cooldown remaining
---@return number
function Spell:GetCooldownRemaining()
    local start, duration = GetSpellCooldown(self:GetID())
    return start + duration - GetTime()
end

-- Get the spell count
---@return number
function Spell:GetCount()
    return GetSpellCount(self:GetID())
end

-- On cooldown
---@return boolean
function Spell:OnCooldown()
    return self:GetCooldownRemaining() > 0
end

-- Cast the spell
---@param actor Actor
---@return boolean
function Spell:Cast(actor)
    if not self:IsKnownAndUsable() then
        return false
    end

    -- Call pre cast function
    if self:GetPreCastFunction() then
        self:GetPreCastFunction()(self)
    end

    -- Check if the mouse was looking
    self.wasLooking = IsMouselooking() or false

    -- if actor:GetToken() contains 'nameplate' then we need to use Object wrapper to cast
    local u = actor:GetToken()

    if type(u) == "string" and string.find(u, 'nameplate') then
        u = Object(u)
    end

    -- Cast the spell
    Unlock(CastSpellByName(self:GetName(), u))

    -- Set the last cast time
    self.lastCastAttempt = GetTime()

    -- Call post cast function
    if self:GetOnCastFunction() then
        self:GetOnCastFunction()(self)
    end

    return true
end

-- Get post cast func
---@return boolean | fun(self:Spell)
function Spell:GetPostCastFunction()
    return self.PostCastFunc
end

-- Check if the spell is known
---@return boolean
function Spell:IsKnown()
    local isKnown = IsSpellKnown(self:GetID())
    local isPlayerSpell = IsPlayerSpell(self:GetID())
    return isKnown or isPlayerSpell
end

-- Check if the spell is on cooldown
---@return boolean
function Spell:IsOnCooldown()
    return select(2, GetSpellCooldown(self:GetID())) > 0
end

-- Check if the spell is usable
---@return boolean
function Spell:IsUsable()
    local usable, noMana = IsUsableSpell(self:GetID())
    return usable and not noMana
end

-- Check if the spell is castable
---@return boolean
function Spell:IsKnownAndUsable()
    return self:IsKnown() and not self:IsOnCooldown() and self:IsUsable()
end

-- Set a script to run before the spell has been cast
---@param func fun(spell:Spell)
---@return Spell
function Spell:PreCast(func)
    self.PreCastFunc = func
    return self
end

-- Set a script to run after the spell has been cast
---@param func fun(spell:Spell)
---@return Spell
function Spell:OnCast(func)
    self.OnCastFunc = func
    return self
end

-- Get was looking
---@return boolean
function Spell:GetWasLooking()
    return self.wasLooking
end

-- Click the spell
---@param x number | Vector3
---@param y? number
---@param z? number
---@return boolean
function Spell:Click(x, y, z)
    if type(x) == 'table' then
        -- Have to cast first to get the annotations working
        x = x --[[@as Vector3]]
        y = x.y
        z = x.z
        x = x.x
    end
    if SpellIsTargeting() then
        MouselookStop()
        ClickPosition(x, y, z)
        if self:GetWasLooking() then
            MouselookStart()
        end
        return true
    end
    return false
end

-- Check if the spell is castable and cast it
---@return boolean | nil
function Spell:HasRange()
    return SpellHasRange(self:GetName())
end

-- Get the range of the spell
---@return number
---@return number
function Spell:GetRange()
    local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(self:GetID())
    return maxRange, minRange
end

-- Check if the spell is in range of the actor
---@param actor Actor
---@return boolean
function Spell:IsInRange(actor)
    local Player = Boop.ActorManager:Get('player')

    if not Player or not Player:Exists() then return false end

    -- Range for Shadowstrike is wonky, since in stealth its 25yd, but
    -- outside of that its melee.
    if self:GetID() == 185438 and Player:IsStealthed() then
        local distance = Player:GetDistance(actor)

        return distance <= 25
    else
        local hasRange = self:HasRange()
    
        if hasRange == false then
            return true
        end

        if hasRange == nil then
            return Player:InMelee(actor)
        end

        local inRange = IsSpellInRange(self:GetName(), actor:GetToken())
    
        if inRange == 1 then
            return true
        end

        return false
    end
end

-- Get the last cast time
---@return number | nil
function Spell:GetLastCastTime()
    return self.lastCastAt
end

-- Get time since last cast
---@return number
function Spell:GetTimeSinceLastCast()
    if not self:GetLastCastTime() then
        return math.huge
    end
    return GetTime() - self:GetLastCastTime()
end

-- Get the time since the last cast attempt
---@return number
function Spell:GetTimeSinceLastCastAttempt()
    if not self.lastCastAttempt then
        return math.huge
    end
    return GetTime() - self.lastCastAttempt
end

-- Get the spells charges
---@return number
function Spell:GetCharges()
    return select(1, GetSpellCharges(self:GetID()))
end

function Spell:GetMaxCharges()
    return select(2, GetSpellCharges(self:GetID()))
end

function Spell:GetCastLength()
    return select(4, GetSpellInfo(self:GetID()))
end

-- IsMagicDispel
---@return boolean
function Spell:IsMagicDispel()
    return ({
        [88423] = true
    })[self:GetID()]
end

-- IsCurseDispel
---@return boolean
function Spell:IsCurseDispel()
    return ({
        [88423] = true
    })[self:GetID()]
end

-- IsPoisonDispel
---@return boolean
function Spell:IsPoisonDispel()
    return ({
        [88423] = true
    })[self:GetID()]
end

-- IsDiseaseDispel
---@return boolean
function Spell:IsDiseaseDispel()
    return ({})[self:GetID()]
end

-- Get the spells charges
---@return number
function Spell:GetChargesFractional()
    local charges, maxCharges, start, duration = GetSpellCharges(self:GetID())

    if charges == maxCharges then
        return maxCharges
    end

    if charges == 0 then
        return 0
    end

    local timeSinceStart = GetTime() - start
    local timeLeft = duration - timeSinceStart
    local timePerCharge = duration / maxCharges
    local chargesFractional = charges + (timeLeft / timePerCharge)

    return chargesFractional
end

-- Get the spells charges remaining
---@return number
function Spell:GetChargesRemaining()
    local charges, maxCharges, start, duration = GetSpellCharges(self:GetID())
    return charges
end

-- IsSpell
---@param spell Spell
---@return boolean
function Spell:IsSpell(spell)
    return self:GetID() == spell:GetID()
end

-- GetCost
---@return number
function Spell:GetCost()
    local cost = GetSpellPowerCost(self:GetID())
    ---@diagnostic disable-next-line: undefined-field
    return cost and cost.cost or 0
end

-- IsFree
---@return boolean
function Spell:IsFree()
    return self:GetCost() == 0
end

return Spell