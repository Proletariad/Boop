local NN,
---@type Boop
Boop = ...

---@type Actor
local Actor = Boop:Require("~/ActorManager/Actor/Actor.lua")

-- A table that houses all information regarding actors in the world.
---@class ActorManager
---@field customActors table<string, Cacheable>
---@field actors table<string, Actor>
---@field cache Cache
---@field friends List
---@field enemies List
local ActorManager = {
    customActors = {},
    actors = {},
    cache = Boop.Cache:New(),
    friends = Boop.List:New(),
    enemies = Boop.List:New()
}

-- Gets or creates an actor
---@param token string
---@return Actor
function ActorManager:Get(token)
    if self.customActors[token] then
        if not self.cache:IsCached(token) then
            self.customActors[token]:Update()
            self.cache:Set(token, self.customActors[token], 0.5)
        end

        return self.customActors[token] --[[@as Actor]]
    end

    local tguid = ObjectGUID(token)

    if tguid and self.actors[tguid] == nil then
        if token == 'none' then
            self.actors['none'] = Actor:New()
        else
            self.actors[tguid] = Actor:New(Object(tguid))
        end
    end

    return Boop.Cacheable:New(self.actors[tguid], function()
        local tguid = ObjectGUID(token) or "none"

        if self.actors[tguid] == nil then
            if token == 'none' then
                self.actors['none'] = Actor:New()
            else
                self.actors[tguid] = Actor:New(Object(tguid))
            end
        end
        return self.actors[tguid]
    end) --[[@as Actor]]
end

-- Get an actor by guid
---@param guid string
---@return Actor
function ActorManager:GetActor(guid)
    return self.actors[guid]
end

-- Set aan actor by guid
---@param actor Actor
---@return nil
function ActorManager:SetActor(actor)
    local guid = actor:GetGUID()

    if guid then
        self.actors[guid] = actor
    end
end

-- Create a custom actor and cache it for .5 seconds
---@param token string
---@param cb fun():Actor
---@return Actor
function ActorManager:CreateCustomActor(token, cb)
    local actor = cb()
    local cachedActor = Boop.Cacheable:New(actor, cb)

    if actor == nil then
        error("ActorManager:CreateCustomActor - Invalid unit: " .. token)
    end

    if self.customActors[token] == nil then
        self.customActors[token] = cachedActor
    end

    self.cache:Set(token, cachedActor, 0.5)

    return cachedActor
end

-- Refresh all lists
---@return nil
function ActorManager:RefreshLists()
    self.friends:clear()
    self.enemies:clear()

    ---@param type "Unit" | "Player" | "ActivePlayer"
    local function LoopObjects(type)
        local objects = ObjectManager(type) or {}

        for _, object in pairs(objects) do
            local actor = self:GetActor(object)

            if not actor then
                actor = Actor:New(object)
                self:SetActor(actor)
            end

            if actor:IsPlayer() and (actor:IsInParty() or actor == self['player']) then
                self.friends:push(actor)
            elseif actor:Exists() and actor:IsEnemy() and actor:IsAlive() then
                local Player = self:Get("player")

                if Player and Player:Exists() and actor:IsAffectingCombat() and Player:CanSee(actor) then
                    self.enemies:push(actor)
                end
            end
        end
    end

    LoopObjects("Unit")
    LoopObjects("Player")
    LoopObjects("ActivePlayer")
end

-- Enumerates all friendly actors in the battlefield
---@param cb fun(unit: Actor):boolean
---@return nil
function ActorManager:EnumFriends(cb)
    self.friends:each(function(unit)
        if cb(unit) then
            return true
        end
    end)
end

-- Enumerates all in combat enemy actors in the battlefield
---@param cb fun(unit: Actor):boolean
---@return nil
function ActorManager:EnumEnemies(cb)
    self.enemies:each(function(unit)
        if cb(unit) then
            return true
        end
    end)
end

-- Get the number of friends with a buff (party/raid members)
---@param spell Spell
---@return number
function ActorManager:GetNumFriendsWithBuff(spell)
    local count = 0
    self:EnumFriends(function(unit)
        if unit:GetAuras():FindMy(spell):IsUp() then
            count = count + 1
        end
        return false
    end)
    return count
end

-- Get the number of friends alive (party/raid members)
---@return number
function ActorManager:GetNumFriendsAlive()
    local count = 0
    self:EnumFriends(function(unit)
        if unit:IsAlive() then
            count = count + 1
        end
        return false
    end)
    return count
end

-- Get the friend with the most friends within a given radius (party/raid members)
---@param radius number
---@return Actor | nil
---@return table
function ActorManager:GetFriendWithMostFriends(radius)
    local actor = nil
    local count = 0
    local friends = {}
    self:EnumFriends(function(u)
        if u:IsAlive() then
            local c = 0
            self:EnumFriends(function(other)
                if other:IsAlive() and u:GetDistance(other) <= radius then
                    c = c + 1
                end
                return false
            end)
            if c > count then
                actor = u
                count = c
                friends = {}
                self:EnumFriends(function(other)
                    if other:IsAlive() and u:GetDistance(other) <= radius then
                        table.insert(friends, other)
                    end
                    return false
                end)
            end
        end
        return false
    end)
    return actor, friends
end

-- Get the enemy with the most enemies within a given radius
function ActorManager:GetEnemyWithMostEnemies(radius)
    local unit = nil
    local count = 0
    local enemies = {}
    self:EnumEnemies(function(u)
        if u:IsAlive() then
            local c = 0
            self:EnumEnemies(function(other)
                if other:IsAlive() and u:GetDistance(other) <= radius then
                    c = c + 1
                end
                return false
            end)
            if c > count then
                unit = u
                count = c
                enemies = {}
                self:EnumEnemies(function(other)
                    if other:IsAlive() and u:GetDistance(other) <= radius then
                        table.insert(enemies, other)
                    end
                    return false
                end)
            end
        end
        return false
    end)
    return unit, enemies
end

return ActorManager