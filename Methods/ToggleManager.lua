---@alias Toggle { x: number, icon: number, state: boolean, id: string, texture?: Texture }

local BUTTON_SIZE = 54

---@class ToggleManager
local ToggleManager = {
  ---@type table<string, Toggle>
  toggles = {}
}

---@return number
function ToggleManager:NumActiveToggles()
  local count = 0

  for i, toggle in pairs(self.toggles) do
    count = count + 1
  end

  return count
end

---@param newToggle { icon: number, state: boolean, id: string }
function ToggleManager:Add(newToggle)
  if self.toggles[newToggle.id] then
    self.toggles[newToggle.id].icon = newToggle.icon
    self.toggles[newToggle.id].state = newToggle.state
  else
    local highestX = nil

    for i, toggle in pairs(self.toggles) do
      if highestX == nil  or toggle.x > highestX then
        highestX = toggle.x
      end
    end

    if highestX == nil then
      highestX = 2
    else
      highestX = highestX + BUTTON_SIZE
    end

    self.toggles[newToggle.id] = {
      x = highestX,
      state = newToggle.state,
      icon = newToggle.icon,
      id = newToggle.id
    }
  end
end

function ToggleManager:Refresh()
  for i, toggle in pairs(self.toggles) do
    if not toggle.texture then
      local frame = CreateFrame("Frame", nil, UIParent)
      frame:SetSize(BUTTON_SIZE, BUTTON_SIZE)
      frame:SetPoint("BOTTOMLEFT", toggle.x, 230)
      
      local Texture = frame:CreateTexture()
      Texture:SetAllPoints(frame)
      Texture:SetTexture(toggle.icon)
      if not toggle.state then
        Texture:SetDesaturated(true)
      end
      self.toggles[toggle.id].texture = Texture
    end
  end
end

---@param id string
function ToggleManager:Toggle(id)
  if self.toggles[id] then
    self.toggles[id].state = not self.toggles[id].state

      local desaturation = self.toggles[id].texture:GetDesaturation()

      if not self.toggles[id].state and desaturation == 0 then
        self.toggles[id].texture:SetDesaturated(true)
      elseif self.toggles[id].state and desaturation == 1 then
        self.toggles[id].texture:SetDesaturated(false)
      end
  end
end

---@param id string
---@return boolean
function ToggleManager:GetState(id)
  if self.toggles[id] then return self.toggles[id].state else return false end
end

return ToggleManager