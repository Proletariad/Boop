local NN = ... 

---@class Boop
---@field DebugMode boolean
---@field Enabled boolean
---@field PausedModules table<string, { duration: number, requestTime: number }>
local Boop = {
    DebugMode = false,
    Enabled = false,
    PausedModules = {},
    Modules = {}
}

Boop.__index = Boop

-- Will load and run files.
---@param file string
function Boop:Require(file)
    if file:sub(1, 1) == "@" then
        -- Use '@' as a short hand to fetch routine files.
        file = file:sub(2)
        return NN:Require('/scripts/Boop/Routines/' .. file, Boop)
    elseif file:sub(1, 1) == "~" then
        -- Use '~' as a short hand to fetch method files
        file = file:sub(2)
        return NN:Require('/scripts/Boop/Methods' .. file, Boop)
    else
        return NN:Require('/scripts/Boop/' .. file, Boop)
    end
end

function Boop:Print(...)
    local args = { ... }
    local str = "|cFFDF362D[Boop]|r |cFFFFFFFF"
    for i = 1, #args do
        str = str .. tostring(args[i]) .. " "
    end
    print(str)
end

-- Will print debug info if enabled.
function Boop:Debug(...)
    if not Boop.DebugMode then
        return
    end
    local args = {...}
    local str = "|cFFDF6520[Boop]|r |cFFFFFFFF"
    for i = 1, #args do
        str = str .. tostring(args[i]) .. " "
    end
    print(str)
end

---@type Cache
Boop.Cache = Boop:Require("~/Cache.lua")

---@type Cacheable
Boop.Cacheable = Boop:Require("~/Cacheable.lua")

---@type List
Boop.List = Boop:Require("~/List.lua")

---@type Vector3
Boop.Vector3 = Boop:Require("~/Vector3.lua")

---@type ActorManager
Boop.ActorManager = Boop:Require("~/ActorManager/ActorManager.lua")

---@type Spell
Boop.Spell = Boop:Require("~/Spell.lua")

---@type SpellManager
Boop.SpellManager = Boop:Require("~/SpellManager.lua")

---@type Command
Boop.Command = Boop:Require("~/Command.lua")

---@type ToggleManager
Boop.ToggleManager = Boop:Require("~/ToggleManager.lua")

---@type Sequencer
Boop.Sequencer = Boop:Require("~/Sequencer.lua")

---@type EventManager
Boop.EventManager = Boop:Require("~/EventManager.lua")

---@type Module
Boop.Module = Boop:Require("~/Module.lua")

---@param module Module
function Boop:Register(module)
    table.insert(Boop.Modules, module)
    Boop:Print("Registered", module)
end

-- Find a module by name
---@return Module | nil
function Boop:FindModule(name)
    for i = 1, #Boop.Modules do
        if Boop.Modules[i].name == name then
            return Boop.Modules[i]
        end
    end

    return nil
end

Boop.EventManager:RegisterWoWEvent('UNIT_AURA', function(unit, auras)
    local u = Boop.ActorManager:Get(unit)

    if u then
        u:GetAuras():OnUpdate(auras)
    end
end)

Boop.EventManager:RegisterWoWEvent("UNIT_SPELLCAST_SUCCEEDED", function(...)
    local unit, castGUID, spellID = ...

    local spell = Boop.SpellManager:GetIfRegistered(spellID)

    if unit == "player" and spell then
        spell.lastCastAt = GetTime()

        if spell:GetPostCastFunction() then
            spell:GetPostCastFunction()(spell)
        end
    end
end)

Boop.Ticker = C_Timer.NewTicker(0.1, function()
    for k, v in pairs(Boop.PausedModules) do
        if (v.duration + v.requestTime) < GetTime() then
            Boop:Print('Module ', k, ' unpaused.')
            Boop.PausedModules[k] = nil
        end
    end

    Boop.ToggleManager:Refresh()

    if Boop.Enabled then
        Boop.ActorManager:RefreshLists()
        for i = 1, #Boop.Modules do
            Boop.Modules[i]:Tick()
        end
    end
end)

local Command = Boop.Command:New('boop')

Command:Register('toggle', 'Toggle boop on/off', function()
    Boop.Enabled = not Boop.Enabled
    if Boop.Enabled then
        Boop:Print("Enabled")
    else
        Boop:Print("Disabled")
    end
end)

Command:Register('debug', 'Toggle debug mode on/off', function()
    Boop.DebugMode = not Boop.DebugMode
    if Boop.DebugMode then
        Boop:Print("Debug mode enabled")
    else
        Boop:Print("Debug mode disabled")
    end
end)

Command:Register('module', 'Toggle a module on/off', function(args)
    local module = Boop:FindModule(args[2])
    if module then
        module:Toggle()
        if module.enabled then
            Boop:Print("Enabled", module.name)
        else
            Boop:Print("Disabled", module.name)
        end
    else
        Boop:Print("Module not found")
    end
end)

Command:Register('pause', 'Pause a module for X seconds', function (args)
    if Boop.Enabled then
        local duration = args[3]
        local moduleName = args[2]
    
        local RequestedModule = Boop:FindModule(moduleName)
    
        if RequestedModule and not Boop.PausedModules[moduleName] then
            Boop:Print("Pausing module ", moduleName, " for ", duration)
            Boop.PausedModules[moduleName] = { duration = duration, requestTime = GetTime() }
        elseif not Boop.PausedModules[moduleName] then
            Boop:Print("Unable to find module ", moduleName)
        end
    end
end)

if UnitClass('player') == 'Rogue' then
    if GetSpecialization() == 1 then
    elseif GetSpecialization() == 2 then
    elseif GetSpecialization() == 3 then
        Boop:Require("@Rogue/Subtlety")
        Unlock('RunMacroText', '/boop module subtlety')
    end
end