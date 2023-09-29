local NN,
---@type Boop
Boop = ...

---@type AuraManager
local AuraManager = Boop:Require("~/ActorManager/Actor/AuraManager/AuraManager.lua")

-- Create a new Actor class
---@class Actor
---@field cache nil | Cache
---@field aura_manager nil | AuraManager
---@field actor nil | string
---@field ttd_ticker cbObject | boolean
---@field ttd number
---@field regression_history { time: number, percent: number }
local Actor = {
    cache = nil,
    aura_manager = nil,
    actor = nil,
    ttd_ticker = false,
    ttd = 0,
    id = nil,
}

Actor.__index = Actor

-- Equals
---@param other Actor
---@return boolean
function Actor:__eq(other)
    return UnitIsUnit(self:GetToken(), other:GetToken())
end

---@return string
function Actor:__tostring()
    return "Actor.__Actor(" .. tostring(self:GetToken()) .. ")" .. " - " .. (self:GetName() or '')
end

-- Constructor
---@param token string | nil
---@return Actor
function Actor:New(token)
    local self = setmetatable({}, Actor)
    self.actor = token
    self.cache = Boop.Cache:New()
    self.aura_manager = AuraManager:New(self)
    self.regression_history = {}
    return self
end

---@return string
function Actor:GetToken()
    if not self.actor then
        return "none"
    end
    return self.actor
end

-- Get the actors GUID
---@return string
function Actor:GetGUID()
    return ObjectGUID(self:GetToken())
end

-- Check if the actor is valid
---@return boolean
function Actor:IsValid()
    return self:GetToken() ~= nil and self:Exists()
end

-- Check if the actor exists in the OM
---@return boolean
function Actor:Exists()
    return ObjectExists(self:GetToken())
end

-- Get the actors name
---@return string | nil
function Actor:GetName()
    return UnitName(self:GetToken())
end

-- Get the actors health
---@return number
function Actor:GetHealth()
    return UnitHealth(self:GetToken())
end

-- Get the actors max health
---@return number
function Actor:GetMaxHealth()
    return UnitHealthMax(self:GetToken())
end

-- Get the actors health percentage
---@return number
function Actor:GetHealthPercent()
    return self:GetHealth() / self:GetMaxHealth() * 100
end

-- Get realized health
---@return number
function Actor:GetRealizedHealth()
    return self:GetHealth() - self:GetHealAbsorbedHealth()
end

-- get realized health percentage
---@return number
function Actor:GetRealizedHP()
    return self:GetRealizedHealth() / self:GetMaxHealth() * 100
end

-- Get the abosorbed actor health
---@return number
function Actor:GetHealAbsorbedHealth()
    return UnitGetTotalHealAbsorbs(self:GetToken())
end

-- Get the actors power type
---@return number
function Actor:GetPowerType()
    return select(UnitPowerType(self:GetToken()), 1)
end

-- Get the actors power
---@param powerType number | nil
---@return number
function Actor:GetPower(powerType)
    local powerType = powerType or self:GetPowerType()
    return UnitPower(self:GetToken(), powerType)
end

-- Get the actors max power
---@param powerType number | nil
---@return number
function Actor:GetMaxPower(powerType)
    local powerType = powerType or self:GetPowerType()
    return UnitPowerMax(self:GetToken(), powerType)
end

-- Get the actors power percentage
---@param powerType number | nil
---@return number
function Actor:GetPowerPercentage(powerType)
    local powerType = powerType or self:GetPowerType()
    return self:GetPower(powerType) / self:GetMaxPower(powerType) * 100
end

-- Get the actors power deficit
---@param powerType number | nil
---@return number
function Actor:GetPowerDeficit(powerType)
    local powerType = powerType or self:GetPowerType()
    return self:GetMaxPower(powerType) - self:GetPower(powerType)
end

-- Get the actors position
---@return Vector3
function Actor:GetPosition()
    local x, y, z = ObjectPosition(self:GetToken())
    return Boop.Vector3:New(x, y, z)
end

-- Check if the actor can see another actor
---@param actor Actor
---@return boolean
function Actor:CanSee(actor)
    if self:GetToken() == nil or not self:Exists() then
        return false
    end

    if actor:GetToken() == nil or not actor:Exists() then
        return false
    end


    local sx, sy, sz = ObjectPosition(self:GetToken())
    local sh = ObjectHeight(self:GetToken())
    local ax, ay, az = ObjectPosition(actor:GetToken())
    local ah = ObjectHeight(actor:GetToken())

    if not sx or not ax then
        return false
    end

    if not sh or not ah then
        return false
    end

    if (ax == 0 and ay == 0 and az == 0) or (sx == 0 and sy == 0 and sz == 0) then
        return true
    end

    local hitFlags = bit.bor(0x1, 0x10, 0x100, 0x100000)

    local x, y, z = TraceLine(sx, sy, sz + sh, ax, ay, az + ah, hitFlags)

    if x == false then
        return true
    end

    return false
end

-- Get the actors distance from another actor
---@param actor Actor
---@return number
function Actor:GetDistance(actor)
    local pself = self:GetPosition()
    local pactor = actor:GetPosition()

    return pself:Distance(pactor)
end

-- Is the actor dead
---@return boolean
function Actor:IsDead()
    return UnitIsDeadOrGhost(self:GetToken())
end

-- Is the actor alive
---@return boolean
function Actor:IsAlive()
    return not UnitIsDeadOrGhost(self:GetToken())
end

-- Is the actor a pet
---@return boolean
function Actor:IsPet()
    return UnitIsUnit(self:GetToken(), "pet")
end

-- Is the actor a friendly actor
---@return boolean
function Actor:IsFriendly()
    return UnitIsFriend("player", self:GetToken())
end

-- IsEnemy
---@return boolean
function Actor:IsEnemy()
    return UnitCanAttack("player", self:GetToken())
end

-- Is the actor a hostile actor
---@return boolean
function Actor:IsHostile()
    return UnitCanAttack(self:GetToken(), 'player')
end

-- Is the actor a boss
---@return boolean
function Actor:IsBoss()
    if UnitClassification(self:GetToken()) == "worldboss" then
        return true
    end

    for i = 1, 5 do
        local bossGUID = UnitGUID("boss" .. i)

        if self:GetGUID() == bossGUID then
            return true
        end
    end

    return false
end

-- Is the actor a target
---@return boolean
function Actor:IsTarget()
    return UnitIsUnit(self:GetToken(), "target")
end

-- Is the actor a focus
---@return boolean
function Actor:IsFocus()
    return UnitIsUnit(self:GetToken(), "focus")
end

-- Is the actor a mouseover
---@return boolean
function Actor:IsMouseover()
    return UnitIsUnit(self:GetToken(), "mouseover")
end

-- Is the actor a tank
---@return boolean
function Actor:IsTank()
    return UnitGroupRolesAssigned(self:GetToken()) == "TANK"
end

-- Is the actor a healer
---@return boolean
function Actor:IsHealer()
    return UnitGroupRolesAssigned(self:GetToken()) == "HEALER"
end

-- Is the actor a damage dealer
---@return boolean
function Actor:IsDamage()
    return UnitGroupRolesAssigned(self:GetToken()) == "DAMAGER"
end

-- Is the actor a player
---@return boolean
function Actor:IsPlayer()
    return UnitIsPlayer(self:GetToken())
end

-- Is the actor a player controlled actor
---@return boolean
function Actor:IsPlayerControlled()
    return UnitPlayerControlled(self:GetToken())
end

-- Get if the actor is affecting combat
---@return boolean
function Actor:IsAffectingCombat()
    return UnitAffectingCombat(self:GetToken())
end

-- Get the actors auras
---@return AuraManager
function Actor:GetAuras()
    return self.aura_manager
end

-- Check if the actor is casting a spell
---@return boolean
function Actor:IsCasting()
    return UnitCastingInfo(self:GetToken()) ~= nil
end

function Actor:GetTimeCastIsAt(percent)
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
        self:GetToken())

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(self
            :GetToken())
    end

    if name and startTimeMS and endTimeMS then
        local castLength = endTimeMS - startTimeMS
        local startTime = startTimeMS / 1000
        local timeUntil = (castLength / 1000) * (percent / 100)

        return startTime + timeUntil
    end

    return 0
end

-- Get Casting or channeling spell
---@return Spell | nil
function Actor:GetCastingOrChannelingSpell()
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
        self:GetToken())

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(self
            :GetToken())
    end

    if name then
        return Boop.SpellManager:GetSpell(spellId)
    end

    return nil
end

-- Get the end time of the cast or channel
---@return number
function Actor:GetCastingOrChannelingEndTime()
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
        self:GetToken())

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(self
            :GetToken())
    end

    if name then
        return endTimeMS / 1000
    end

    return 0
end

-- Check if the actor is channeling a spell
---@return boolean
function Actor:IsChanneling()
    return UnitChannelInfo(self:GetToken()) ~= nil
end

-- Check if the actor is casting or channeling a spell
---@return boolean
function Actor:IsCastingOrChanneling()
    return self:IsCasting() or self:IsChanneling()
end

-- Check if the actor can attack the target
---@param actor Actor
---@return boolean
function Actor:CanAttack(actor)
    return UnitCanAttack(self:GetToken(), actor:GetToken())
end

---@return number
function Actor:GetChannelOrCastPercentComplete()
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
        self:GetToken())

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(self
            :GetToken())
    end

    if name and startTimeMS and endTimeMS then
        local start = startTimeMS / 1000
        local finish = endTimeMS / 1000
        local current = GetTime()

        return ((current - start) / (finish - start)) * 100
    end
    return 0
end

-- Check if actor is interruptible
---@return boolean
function Actor:IsInterruptible()
    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
        self:GetToken())

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(self
            :GetToken())
    end

    if name then
        return not notInterruptible
    end

    return false
end

-- Check if actor is interruptible
---@param percent number
---@param ignoreInterruptible? boolean
---@return boolean
function Actor:IsInterruptibleAt(percent, ignoreInterruptible)
    if not ignoreInterruptible and not self:IsInterruptible() then
        return false
    end

    local percent = percent or math.random(2, 5)

    local castPercent = self:GetChannelOrCastPercentComplete()
    if castPercent >= percent then
        return true
    end

    return false
end

-- Get the number of enemies in a given range of the actor and cache the result for .5 seconds
---@param range number
---@return number
function Actor:GetEnemies(range)
    local enemies = self.cache:Get("enemies_" .. range)

    if enemies then
        return enemies
    end

    local count = 0

    Boop.ActorManager:EnumEnemies(function(actor)
        if not self:IsUnit(actor) and self:IsWithinCombatDistance(actor, range) and actor:IsAlive() and
            actor:IsEnemy() then
            count = count + 1
        end
        return false
    end)

    self.cache:Set("enemies_" .. range, count, 0.5)
    return count
end

-- Is in vehicle
---@return boolean
function Actor:IsInVehicle()
    return UnitInVehicle(self:GetToken())
end

-- Is moving
---@return boolean
function Actor:IsMoving()
    return GetUnitSpeed(self:GetToken()) > 0
end

-- Is moving at all
---@return boolean
function Actor:IsMovingAtAll()
    return UnitMovementFlag(self:GetToken()) ~= 0
end

-- IsUnit
---@param actor Actor
---@return boolean
function Actor:IsUnit(actor)
    return UnitIsUnit(self:GetToken(), actor and actor:GetToken() or 'none')
end

-- IsTanking
---@param actor Actor
---@return boolean
function Actor:IsTanking(actor)
    local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(self:GetToken(), actor:GetToken())
    return isTanking
end

-- IsFacing
---@param actor Actor
---@return boolean
function Actor:IsFacing(actor)
    local rot = ObjectRotation(self:GetToken())
    local x, y, z = ObjectPosition(self:GetToken())
    local x2, y2, z2 = ObjectPosition(actor:GetToken())

    if not x or not x2 or not rot then
        return false
    end

    local angle = math.atan2(y2 - y, x2 - x) - rot
    angle = math.deg(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end

    return math.abs(angle) < 90
end

-- IsBehind
---@param actor Actor
---@return boolean
function Actor:IsBehind(actor)
    local rot = ObjectRotation(actor:GetToken())
    local x, y, z = ObjectPosition(actor:GetToken())
    local x2, y2, z2 = ObjectPosition(self:GetToken())

    if not x or not x2 then
        return false
    end

    local angle = math.atan2(y2 - y, x2 - x) - rot
    angle = math.deg(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end

    return math.abs(angle) > 90
end

-- IsInfront
---@param actor Actor
---@return boolean
function Actor:IsInfront(actor)
    return not self:IsBehind(actor)
end

---@return number
function Actor:GetMeleeBoost()
    if IsPlayerSpell(196924) then
        return 3
    end
    return 0
end

-- InMelee
---@param actor Actor
---@return boolean
function Actor:InMelee(actor)
    local x, y, z = ObjectPosition(self:GetToken())
    local x2, y2, z2 = ObjectPosition(actor:GetToken())

    if not x or not x2 then
        return false
    end

    local scr = CombatReach(self:GetToken())
    local ucr = CombatReach(actor:GetToken())

    if not scr or not ucr then
        return false
    end

    local dist = math.sqrt((x - x2) ^ 2 + (y - y2) ^ 2 + (z - z2) ^ 2)
    local maxDist = math.max((scr + 1.3333) + ucr, 5.0)
    maxDist = maxDist + 1.0 + self:GetMeleeBoost()

    return dist <= maxDist
end

-- In party
---@return boolean
function Actor:IsInParty()
    return UnitInParty(self:GetToken())
end

-- Linear regression between time and percent to something
---@param time table
---@param percent table
---@return number, number
function Actor:LinearRegression(time, percent)
    local x = time
    local y = percent

    local n = #x
    local sum_x = 0
    local sum_y = 0
    local sum_xy = 0
    local sum_xx = 0
    local sum_yy = 0

    for i = 1, n do
        sum_x = sum_x + x[i]
        sum_y = sum_y + y[i]
        sum_xy = sum_xy + x[i] * y[i]
        sum_xx = sum_xx + x[i] * x[i]
        sum_yy = sum_yy + y[i] * y[i]
    end

    local slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
    local intercept = (sum_y - slope * sum_x) / n

    return slope, intercept
end

-- Use linear regression to get the health percent at a given time in the future
---@param time number
---@return number
function Actor:PredictHealth(time)
    local x = {}
    local y = {}

    if #self.regression_history > 60 then
        table.remove(self.regression_history, 1)
    end

    table.insert(self.regression_history, { time = GetTime(), percent = self:GetHealthPercent() })

    for i = 1, #self.regression_history do
        local entry = self.regression_history[i]
        table.insert(x, entry.time)
        table.insert(y, entry.percent)
    end

    local slope, intercept = self:LinearRegression(x, y)
    return slope * time + intercept
end

-- Use linear regression to guess the time until a given health percent
---@param percent number
---@return number
function Actor:PredictTime(percent)
    local x = {}
    local y = {}

    if #self.regression_history > 60 then
        table.remove(self.regression_history, 1)
    end

    table.insert(self.regression_history, { time = GetTime(), percent = self:GetHealthPercent() })

    for i = 1, #self.regression_history do
        local entry = self.regression_history[i]
        table.insert(x, entry.time)
        table.insert(y, entry.percent)
    end

    local slope, intercept = self:LinearRegression(x, y)
    return (percent - intercept) / slope
end

-- Start time to die ticker
function Actor:StartTTDTicker()
    if self.ttd_ticker then
        return
    end

    self.ttd_ticker = C_Timer.NewTicker(0.5, function()
        local timeto = self:PredictTime(0) - GetTime()
        self.ttd = timeto
    end)
end

-- Time until death
---@return number
function Actor:TimeToDie()
    if self:IsDead() then
        self.regression_history = {}
        if self.ttd_ticker then
            ---@diagnostic disable-next-line: param-type-mismatch
            self.ttd_ticker:Cancel()
            self.ttd_ticker = false
        end
        return 0
    end

    if not self.ttd_ticker then
        self:StartTTDTicker()
    end

    -- If there's not enough data to make a prediction return 0 unless the actor has more than 5 million health
    if #self.regression_history < 5 and self:GetMaxHealth() < 5000000 then
        return 0
    end

    -- if the actor has more than 5 million health but there's not enough data to make a prediction we can assume there's roughly 250000 damage per second and estimate the time to die
    if #self.regression_history < 5 and self:GetMaxHealth() > 5000000 then
        return self:GetMaxHealth() /
            250000 -- 250000 is an estimate of the average damage per second a well geared group will average
    end

    if self.ttd ~= self.ttd or self.ttd < 0 or self.ttd == math.huge then
        return 0
    end

    return self.ttd
end

-- Get actors gcd time
---@return number
function Actor:GetGCD()
    local start, duration = GetSpellCooldown(61304)
    if start == 0 then
        return 0
    end

    return duration - (GetTime() - start)
end

-- Get actors max gcd time
--[[
    The GCD without Haste is 1.5 seconds
With 50% Haste the GCD is 1 second
With 100% Haste the GCD is 0.5 seconds
The GCD won't drop below 1 second
More than 50% Haste will drop a spell below 1 second

]]
---@return number
function Actor:GetMaxGCD()
    local haste = UnitSpellHaste(self:GetToken())
    if haste > 50 then
        haste = 50
    end

    -- if the actor uses focus their gcd is 1.0 seconds not 1.5
    local base = 1.5
    if self:GetPowerType() == 3 then
        base = 1.0
    end
    return base / (1 + haste / 100)
end

-- IsStealthed
---@return boolean
function Actor:IsStealthed()
    local Stealth = Boop.SpellManager:GetSpell(1784)
    local Shadowmeld = Boop.SpellManager:GetSpell(58984)

    return self:GetAuras():FindAny(Stealth):IsUp() or self:GetAuras():FindAny(Shadowmeld):IsUp()
end

-- get the actors combat reach
---@return number
function Actor:GetCombatReach()
    return CombatReach(self:GetToken())
end

-- Get the actors combat distance (distance - combat reach (realized distance))
---@return number
function Actor:GetCombatDistance(Target)
    return self:GetDistance(Target) - Target:GetCombatReach()
end

-- Is the actor within distance of the target (combat reach + distance)
--- If the target is within 8 combat yards (8 + combat reach) of the actor
---@param Target Actor
---@param Distance number
---@return boolean
function Actor:IsWithinCombatDistance(Target, Distance)
    if not Target:Exists() then
        return false
    end
    return self:GetDistance(Target) <= Distance + Target:GetCombatReach()
end

-- Check if the actor is within X yards (consider combat reach)
---@param Target Actor
---@param Distance number
---@return boolean
function Actor:IsWithinDistance(Target, Distance)
    return self:GetDistance(Target) <= Distance
end


function Actor:GetFacing()
    return ObjectRotation(self:GetToken()) or 0
end

return Actor