-- Create a wow command handler class
---@class Command
---@field command string
---@field commands Command.commands[]
---@field prefix string
local Command = {}

---@class Command.commands
---@field helpmsg string
---@field cb fun(args: table)

Command.__index = Command

---@return string
function Command:__tostring()
    return "Command(" .. self.command .. ")"
end

---@param prefix string
function Command:New(prefix)
    local self = setmetatable({}, Command)

    self.prefix = prefix
    self.commands = {}

    _G['SLASH_' .. prefix:upper() .. '1'] = "/" .. prefix

    SlashCmdList[prefix:upper()] = function(msg, editbox)
        self:OnCommand(msg)
    end

    return self
end

---@param command string
---@param helpmsg string
---@param cb fun(args: table)
---@return nil
function Command:Register(command, helpmsg, cb)
    self.commands[command] = {
        helpmsg = helpmsg,
        cb = cb
    }
end

---@param msg string
---@return table
function Command:Parse(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end

    return args
end

---@param msg string
---@return nil
function Command:OnCommand(msg)
    local args = self:Parse(msg)

    if #args == 0 then
        self:PrintHelp()
        return
    end

    local runner = self.commands[args[1]]
    if runner then
        runner.cb(args)
    end
end

---@return nil
function Command:PrintHelp()
    for k, v in pairs(self.commands) do
        print('/' .. self.prefix .. ' ' .. k .. " - " .. v.helpmsg)
    end
end

return Command