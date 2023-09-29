local NN,
---@type Boop
Boop = ...

-- Define a Cacheable class
---@class Cacheable
---@field cache Cache | nil
---@field value any
---@field callback nil | fun():any
local Cacheable = {
    cache = nil,
    callback = nil,
    value = nil,
}

-- On index check the cache to be valid and return the value or reconstruct the value and return it
function Cacheable:__index(k)
    if Cacheable[k] then
        return Cacheable[k]
    end

    if self.cache == nil then
        error("Cacheable:__index: " .. k .. " does not exist")
    end

    if not self.cache:IsCached('self') then
        self.value = self.callback()
        self.cache:Set('self', self.value, 0.5)
    end

    return self.value[k]
end

-- When the object is accessed return the value
---@return string
function Cacheable:__tostring()
    return "Boop.__Cacheable(" .. tostring(self.value) .. ")"
end

-- Create
---@param value any
---@param cb fun():any
function Cacheable:New(value, cb)
    local self = setmetatable({}, Cacheable)

    self.cache = Boop.Cache:New()
    self.value = value
    self.callback = cb

    self.cache:Set('self', self.value, 0.5)

    return self
end

-- Try to update the value
---@return nil
function Cacheable:TryUpdate()
    if self.cache:IsCached("value") then
        self.value = self.callback()
    end
end

-- Update the value
---@return nil
function Cacheable:Update()
    self.value = self.callback()
end

-- Set a new value
---@param value any
function Cacheable:Set(value)
    self.value = value
end

-- Set a new callback
---@param cb fun():any
function Cacheable:SetCallback(cb)
    self.callback = cb
end

return Cacheable