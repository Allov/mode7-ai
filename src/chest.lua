local Constants = require('src.constants')
local GameData = require('src.gamedata')

local Chest = {
  x = 0,
  y = 0,
  z = 0,  -- Will be constant height now
  radius = 60,           -- Doubled from 30 to 60
  interactRadius = 120,  -- Doubled from 60 to 120
  isOpen = false,
  age = 0
}

function Chest:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Chest:init(x, y)
  self.x = x
  self.y = y
  self.z = 0  -- Fixed height off ground
  self.isOpen = false
  self.age = 0
  return self
end

function Chest:update(dt)
  if not self.isOpen then
    local dx = _G.player.x - self.x
    local dy = _G.player.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance < self.radius then  -- Changed from interactRadius to radius
      self.isOpen = true
      
      -- Determine rarity
      local roll = math.random()
      local rarity
      if roll < 0.6 then         -- 60% chance for common
        rarity = 1
      elseif roll < 0.9 then     -- 30% chance for uncommon
        rarity = 2
      else                       -- 10% chance for rare
        rarity = 3
      end
      
      -- Get all power-ups of the chosen rarity
      local possibleTypes = {}
      for type, data in pairs(GameData.POWERUP_TYPES) do
        if data.rarity == rarity then
          table.insert(possibleTypes, type)
        end
      end
      
      if #possibleTypes > 0 then
        -- Choose random power-up of the chosen rarity
        self.spawnPowerUp = {
          x = self.x,
          y = self.y,
          type = possibleTypes[math.random(#possibleTypes)]
        }
      end
      
      return true
    end
  end
  return false
end

return Chest




