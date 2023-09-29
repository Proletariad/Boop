---@class EventManager
---@field frame Frame | nil
local EventManager = {
    frame = CreateFrame("Frame"),
    events = {},
    eventHandlers = {},
    wowEventHandlers = {},
}

EventManager.__index = EventManager

EventManager.frame:SetScript('OnEvent', function(f, event, ...)
    if EventManager.wowEventHandlers[event] then
        for _, callback in ipairs(EventManager.wowEventHandlers[event]) do
            callback(...)
        end
    end
end)

-- Register an event
---@param event string
---@param handler fun(...)
---@return nil
function EventManager:RegisterEvent(event, handler)
    if not self.events[event] then
        self.events[event] = {}
    end

    table.insert(self.events[event], handler)
end

-- Register a wow event
---@param event string
---@param handler fun(...)
---@return nil
function EventManager:RegisterWoWEvent(event, handler)
    if not self.wowEventHandlers[event] then
        self.wowEventHandlers[event] = {}
        self.frame:RegisterEvent(event)
    end

    table.insert(self.wowEventHandlers[event], handler)
end

-- Trigger an event
---@param event string
---@param ... any
---@return nil
function EventManager:TriggerEvent(event, ...)
    if self.events[event] then
        for _, handler in pairs(self.events[event]) do
            handler(...)
        end
    end
end

return EventManager