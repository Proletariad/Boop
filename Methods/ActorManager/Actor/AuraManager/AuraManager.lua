local NN,
---@type Boop
Boop = ...

---@type Aura
local Aura = Boop:Require("~/ActorManager/Actor/AuraManager/Aura/Aura.lua")

local function ForEachAuraHelper(unit, func, continuationToken, ...)
    local n = select('#', ...);
    for i=1, n do
        local slot = select(i, ...);
        local auraInfo = C_UnitAuras.GetAuraDataBySlot(unit, slot);
        local done = func(auraInfo);
        if done then
            return nil;
        end
    end
    return continuationToken;
end

local function ForEachAura(unit, filter, maxCount, func)
    local continuationToken;
    repeat
        continuationToken = ForEachAuraHelper(unit, func, UnitAuraSlots(unit, filter, maxCount, continuationToken));
    until continuationToken == nil;
end

---@alias AuraLookupTable table<number, table<number, Aura>>

-- Create a new AuraManager class
---@class AuraManager
---@field actor Actor
---@field auras AuraLookupTable
---@field playerAuras AuraLookupTable
---@field guid string
---@field instanceIDLookup table<number, number>
local AuraManager = {}

AuraManager.__index = AuraManager

-- Constructor
---@param actor Actor
---@return AuraManager
function AuraManager:New(actor)
    local self = setmetatable({}, AuraManager)

    self.actor = actor
    self.auras = {}
    self.playerAuras = {}
    self.guid = actor:GetGUID()
    self.instanceIDLookup = {}

    return self
end

---@param auras UnitAuraUpdateInfo
---@return nil
function AuraManager:OnUpdate(auras)
    if not auras then
        self:Update()
        return
    end
    local isFullUpdate = auras.isFullUpdate

    if isFullUpdate then
        self:Update()
        return
    end

    local removedAuras = auras.removedAuraInstanceIDs
    local addedAuras = auras.addedAuras
    local updatedAuras = auras.updatedAuraInstanceIDs

    -- Add auras
    if addedAuras and #addedAuras > 0 then
        for i = 1, #addedAuras do
            local aura = Aura:New(addedAuras[i])

            self:AddOrUpdateAuraInstanceID(aura:GetAuraInstanceID(), aura)
        end
    end

    -- DevTools_Dump(addedAuras)
    if updatedAuras and #updatedAuras > 0 then
        for i = 1, #updatedAuras do
            local id = updatedAuras[i]
            local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.actor:GetToken(), id);
            if newAura then
                local aura = Aura:New(newAura)
                self:AddOrUpdateAuraInstanceID(aura:GetAuraInstanceID(), aura)
            end
        end
    end

    -- Remove auras
    if removedAuras and #removedAuras > 0 then
        for i = 1, #removedAuras do
            self:RemoveInstanceID(removedAuras[i])
        end
    end
end

---@param instanceID number
---@return nil
function AuraManager:RemoveInstanceID(instanceID)
    if not self.instanceIDLookup[instanceID] then
        return
    end

    local id = self.instanceIDLookup[instanceID]

    if self.playerAuras[id] and self.playerAuras[id][instanceID] then
        self.playerAuras[id][instanceID] = nil
        self.instanceIDLookup[instanceID] = nil
        return
    end

    if self.auras[id] and self.auras[id][instanceID] then
        self.auras[id][instanceID] = nil
        self.instanceIDLookup[instanceID] = nil
        return
    end
end

-- Update the aura table
---@param instanceID number
---@param aura Aura
---@return nil
function AuraManager:AddOrUpdateAuraInstanceID(instanceID, aura)
    local spellId = aura:GetSpell():GetID()

    self.instanceIDLookup[instanceID] = spellId

    local Player = Boop.ActorManager:Get('player')

    if Player and Player:Exists() and Player:IsUnit(aura:GetSource()) then
        if not self.playerAuras[spellId] then
            self.playerAuras[spellId] = {}
        end

        self.playerAuras[spellId][instanceID] = aura
    else
        if not self.auras[spellId] then
            self.auras[spellId] = {}
        end

        self.auras[spellId][instanceID] = aura
    end
end

-- Get an actors buffs
---@return nil
function AuraManager:GetActorBuffs()
    ForEachAura(self.actor:GetToken(), 'HELPFUL', nil, function(a)
        local aura = Aura:New(a)

        if aura:IsValid() then
            self:AddOrUpdateAuraInstanceID(aura:GetAuraInstanceID(), aura)
        end
    end)
end

-- Get an actors debuffs
---@return nil
function AuraManager:GetActorDebuffs()
    ForEachAura(self.actor:GetToken(), 'HARMFUL', nil, function(a)
        local aura = Aura:New(a)

        if aura:IsValid() then
            self:AddOrUpdateAuraInstanceID(aura:GetAuraInstanceID(), aura)
        end
    end)
end

-- Update auras
---@return nil
function AuraManager:Update()
    self:Clear()

    self:GetActorBuffs()
    self:GetActorDebuffs()
end

-- Get an actors auras
---@return AuraLookupTable
function AuraManager:GetActorAuras()
    if not self.did then
        self.did = true
        self:Update()
    end

    -- For token actors, we need to check if the GUID has changed
    if self.actor:GetGUID() ~= self.guid then
        self.guid = self.actor:GetGUID()
        self:Update()
        return self.auras
    end

    return self.auras
end

-- Get the players auras
---@return AuraLookupTable
function AuraManager:GetMyAuras()
    if not self.did then
        self.did = true
        self:Update()
    end
    -- For token actors, we need to check if the GUID has changed
    if self.actor:GetGUID() ~= self.guid then
        self.guid = self.actor:GetGUID()
        self:Update()
        return self.playerAuras
    end

    return self.playerAuras
end

-- Clear the aura table
---@return nil
function AuraManager:Clear()
    self.auras = {}
    self.playerAuras = {}
    self.instanceIDLookup = {}
end

-- Check if the actor has a specific aura not from the player
---@param spell Spell
---@return Aura
function AuraManager:Find(spell)
    local auras = self:GetActorAuras()
    local aurasub = auras[spell:GetID()]

    if not aurasub then
        return Aura:NewBlankAura()
    end

    for k, a in pairs(aurasub) do
        if a ~= nil then
            if a:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                return a
            else
                self:RemoveInstanceID(a:GetAuraInstanceID())
            end
        end
    end

    return Aura:NewBlankAura()
end

-- Check if the actor has a specific aura from the player
---@param spell Spell
---@return Aura
function AuraManager:FindMy(spell)
    local auras = self:GetMyAuras()
    local aurasub = auras[spell:GetID()]

    if not aurasub then
        return Aura:NewBlankAura()
    end

    for k, a in pairs(aurasub) do
        if a ~= nil then
            if a:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                return a
            else
                self:RemoveInstanceID(a:GetAuraInstanceID())
            end
        end
    end

    return Aura:NewBlankAura()
end

-- Check if the actor has a specific aura from a specific source
---@param spell Spell
---@param source Actor
---@return Aura
function AuraManager:FindFrom(spell, source)
    local auras = self:GetActorAuras()
    local aurasub = auras[spell:GetID()]

    if not aurasub then
        return Aura:NewBlankAura()
    end

    for k, a in pairs(aurasub) do
        if a ~= nil then
            if a:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                if a:GetSource() == source then
                    return a
                end
            else
                self:RemoveInstanceID(a:GetAuraInstanceID())
            end
        end
    end

    return Aura:NewBlankAura()
end

-- Find an actors auras that they have applied
---@param spell Spell
---@return Aura
function AuraManager:FindTheirs(spell)
    local auras = self:GetActorAuras()
    local aurasub = auras[spell:GetID()]

    if not aurasub then
        return Aura:NewBlankAura()
    end

    for k, a in pairs(aurasub) do
        if a ~= nil then
            if a:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                if self.actor:IsUnit(a:GetSource()) then
                    return a
                end
            else
                self:RemoveInstanceID(a:GetAuraInstanceID())
            end
        end
    end

    return Aura:NewBlankAura()
end

-- Find an aura from either the player, or the actor
---@param spell Spell
---@return Aura
function AuraManager:FindAny(spell)
    local a = self:Find(spell)
    if a:IsValid() then
        return a
    end

    return self:FindMy(spell)
end

-- Check if the actor has any purgeable auras
---@return boolean
function AuraManager:HasAnyStealableAura()
    for _, auras in pairs(self:GetActorAuras()) do
        for _, aura in pairs(auras) do
            if aura:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                if aura:GetIsStealable() then
                    return true
                end
            else
                self:RemoveInstanceID(aura:GetAuraInstanceID())
            end
        end
    end

    return false
end

-- Check if the actor has any dispellable auras
---@param spell Spell
---@return boolean
function AuraManager:HasAnyDispelableAura(spell)
    for _, auras in pairs(self:GetActorAuras()) do
        for _, aura in pairs(auras) do
            if aura:IsUp() then -- Handle expired and non refreshed dropoffs not coming in UNIT_AURA
                if aura:IsDebuff() and aura:IsDispelableBySpell(spell) then
                    return true
                end
            else
                self:RemoveInstanceID(aura:GetAuraInstanceID())
            end
        end
    end

    return false
end

return AuraManager