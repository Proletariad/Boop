---@class Module
---@field name string
---@field synced table
---@field enabled boolean
local Module = {}

Module.__index = Module

---@return string
function Module:__tostring()
    return "Boop.__Module(" .. self.name .. ")"
end

---@param name string
---@return Module
function Module:New(name)
    local module = {}
    setmetatable(module, Module)

    module.name = name
    module.enabled = false
    module.synced = {}

    return module
end

-- Enable the module
---@return nil
function Module:Enable()
    self.enabled = true
end

-- Disable the module
---@return nil
function Module:Disable()
    self.enabled = false
end

-- Toggle the module
---@return nil
function Module:Toggle()
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end
end

-- Add a function to the sync list
---@param func function
---@return nil
function Module:Sync(func)
    table.insert(self.synced, func)
end

-- Remove a function from the sync list
---@param func function
---@return nil
function Module:Unsync(func)
    for i = 1, #self.synced do
        if self.synced[i] == func then
            table.remove(self.synced, i)
            return
        end
    end
end

-- Sync
---@return nil
function Module:Tick()
    if self.enabled then
        for i = 1, #self.synced do
            self.synced[i]()
        end
    end
end

return Module