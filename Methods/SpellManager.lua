local NN,
---@type Boop
Boop = ...

-- Create a new SpellManager class
---@class SpellManager
---@field spells table<number, Spell>
local SpellManager = {
    spells = {}
}

SpellManager.__index = SpellManager

-- Get a spell from the SpellManager
---@param id number
---@return Spell
function SpellManager:GetSpell(id)
    if self.spells[id] == nil then
        self.spells[id] = Boop.Spell:New(id)
    end

    return self.spells[id]
end

---@param name string
---@return Spell
function SpellManager:GetSpellByName(name)
    local _, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(name)
    return self:GetSpell(spellID)
end

---@return Spell
function SpellManager:GetIfRegistered(id)
    return self.spells[id]
end

return SpellManager