local NN,
---@type Boop
Boop = ...

---@class AuraFields
---@field name string | nil
---@field icon number | nil
---@field count number
---@field dispelType string?
---@field duration number
---@field expirationTime number
---@field source string | nil
---@field isStealable boolean
---@field nameplateShowPersonal boolean
---@field spellId number
---@field canApplyAura boolean
---@field isBossDebuff boolean
---@field castByPlayer boolean
---@field nameplateShowAll boolean
---@field timeMod number
---@field auraInstanceID number | nil
---@field index number | nil
---@field type "HARMFUL" | "HELPFUL" | nil

---@type AuraFields
local BlankAura = {
    name = nil,
    icon = nil,
    count = 0,
    dispelType = nil,
    duration = 0,
    expirationTime = 0,
    source = nil,
    isStealable = false,
    nameplateShowPersonal = false,
    spellId = 0,
    canApplyAura = false,
    isBossDebuff = false,
    castByPlayer = false,
    nameplateShowAll = false,
    timeMod = 0,
    index = nil,
    type = nil
}

-- Create a new Aura class
---@class Aura
---@field aura AuraFields
local Aura = {}

Aura.__index = Aura

-- Equals
---@param other Aura|Spell
---@return boolean
function Aura:__eq(other)
    if getmetatable(other) == Aura then
        return self:GetSpell():GetID() == other:GetSpell():GetID()
    end

    if getmetatable(other) == Boop.Spell then
        return self:GetSpell():GetID() == other:GetID()
    end

    return false
end

-- tostring
---@return string
function Aura:__tostring()
    return "Boop.__Aura(" .. self:GetSpell():GetID() .. ")" .. " - " .. (self:GetName() or "''")
end

-- Creates and returns a new aura from AuraData
---@param unitAuraInfo AuraData
---@return Aura
function Aura:New(unitAuraInfo)
    local self = setmetatable({}, Aura)

    self.aura = {
        name = unitAuraInfo.name,
        icon = unitAuraInfo.icon,
        count = unitAuraInfo.applications,
        dispelType = unitAuraInfo.dispelName,
        duration = unitAuraInfo.duration,
        expirationTime = unitAuraInfo.expirationTime,
        source = unitAuraInfo.sourceUnit,
        isStealable = unitAuraInfo.isStealable,
        nameplateShowPersonal = unitAuraInfo.nameplateShowPersonal,
        spellId = unitAuraInfo.spellId,
        canApplyAura = unitAuraInfo.canApplyAura,
        isBossDebuff = unitAuraInfo.isBossAura,
        castByPlayer = unitAuraInfo.isFromPlayerOrPlayerPet,
        nameplateShowAll = unitAuraInfo.nameplateShowAll,
        timeMod = unitAuraInfo.timeMod,
        auraInstanceID = unitAuraInfo.auraInstanceID,
        index = nil,
        type = unitAuraInfo.isHarmful and "HARMFUL" or "HELPFUL"
    }

    if self.aura.spellId then
        Boop.SpellManager:GetSpell(self.aura.spellId)
    end

    return self
end

-- Creates and returns a new aura with default data
---@return Aura
function Aura:NewBlankAura()
    local self = setmetatable({}, Aura)

    self.aura = BlankAura

    return self
end

-- Check if the aura is valid
---@return boolean
function Aura:IsValid()
    return self.aura.name ~= nil
end

-- Check if the aura is up
---@return boolean
function Aura:IsUp()
    return self:IsValid() and (self:GetDuration() == 0 or self:GetRemainingTime() > 0)
end

-- Check if the aura is down
---@return boolean
function Aura:IsDown()
    return not self:IsUp()
end

-- Get the auras index
---@return number
function Aura:GetIndex()
    return self.aura.index
end

-- Get the auras type
---@return string
function Aura:GetType()
    return self.aura.type
end

-- Get the auras name
---@return string
function Aura:GetName()
    return self.aura.name
end

-- Get the auras icon
---@return number|nil
function Aura:GetIcon()
    return self.aura.icon
end

-- Get the auras count
---@return number
function Aura:GetCount()
    return self.aura.count
end

-- Get the auras dispel type
---@return string
function Aura:GetDispelType()
    return self.aura.dispelType
end

-- Get the auras duration
---@return number
function Aura:GetDuration()
    return self.aura.duration
end

-- Get the auras remaining time
---@return number
function Aura:GetRemainingTime()
    local remainingTime = self.aura.expirationTime - GetTime()

    if remainingTime < 0 then
        remainingTime = 0
    end

    return remainingTime
end

-- Get the auras expiration time
---@return number
function Aura:GetExpirationTime()
    return self.aura.expirationTime
end

-- Get the auras source
---@return Actor
function Aura:GetSource()
    return Boop.ActorManager:Get(self.aura.source)
end

-- Get the auras stealable status
---@return boolean
function Aura:GetIsStealable()
    return self.aura.isStealable
end

-- Get the auras spell id
---@return Spell | nil
function Aura:GetSpell()
    if self.aura.spellId == BlankAura.spellId then return end
    return Boop.SpellManager:GetSpell(self.aura.spellId)
end

-- Get the auras can apply aura status
---@return boolean
function Aura:GetCanApplyAura()
    return self.aura.canApplyAura
end

-- Get the auras is boss debuff status
---@return boolean
function Aura:GetIsBossDebuff()
    return self.aura.isBossDebuff
end

-- Get the auras cast by player status
---@return boolean
function Aura:GetCastByPlayer()
    return self.aura.castByPlayer
end

-- Get the auras nameplate show all status
---@return boolean
function Aura:GetNameplateShowAll()
    return self.aura.nameplateShowAll
end

-- Get the auras time mod
---@return number
function Aura:GetTimeMod()
    return self.aura.timeMod
end

-- Check if the aura is a buff
---@return boolean
function Aura:IsBuff()
    return self.aura.type == "HELPFUL"
end

-- Check if the aura is a debuff
---@return boolean
function Aura:IsDebuff()
    return self.aura.type == "HARMFUL"
end

-- Get aura instance id
---@return number
function Aura:GetAuraInstanceID()
    return self.aura.auraInstanceID
end

-- Check if the aura is dispelable by a spell
---@param spell Spell
function Aura:IsDispelableBySpell(spell)
    if self:GetDispelType() == nil then
        return false
    end

    if self:GetDispelType() == 'Magic' and spell:IsMagicDispel() then
        return true
    end

    if self:GetDispelType() == 'Curse' and spell:IsCurseDispel() then
        return true
    end

    if self:GetDispelType() == 'Poison' and spell:IsPoisonDispel() then
        return true
    end

    if self:GetDispelType() == 'Disease' and spell:IsDiseaseDispel() then
        return true
    end

    return false
end

return Aura