-- Create a sequencer class that takes a table of actions and executes them in order
---@class Sequencer
---@field resetCondition fun(): boolean
---@field abortCondition fun(): boolean
---@field actions fun(sequencer: Sequencer)[]
local Sequencer = {}
Sequencer.__index = Sequencer

-- Constructor
---@param actions table
---@return Sequencer
function Sequencer:New(actions, resetCondition)
    local self = setmetatable({}, Sequencer)

    self.actions = actions
    self.index = 1

    self.resetCondition = resetCondition

    return self
end

-- Should we reset the sequencer
---@return boolean
function Sequencer:ShouldReset()
    if self.resetCondition then
        return self.resetCondition()
    end

    return false
end

-- Should we abort the sequencer
---@return boolean
function Sequencer:ShouldAbort()
    if self.abortCondition then
        return self.abortCondition()
    end

    return false
end

-- Execute the next action in the sequence if it doesn't return true we need to try it again
---@return boolean
function Sequencer:Next()
    if self:Finished() then
        return false
    end

    local action = self.actions[self.index]
    if action(self) then
        self.index = self.index + 1
        return true
    end

    return false
end

-- Reset the sequencer
---@return nil
function Sequencer:Reset()
    self.index = 1
end

function Sequencer:Execute()
    if self:Next() then
        return true
    end

    return false
end

function Sequencer:Finished()
    return self.index > #self.actions
end

function Sequencer:Abort()
    self.index = #self.actions + 1
end

return Sequencer