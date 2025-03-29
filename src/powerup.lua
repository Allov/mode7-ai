local Constants = require('src.constants')
local GameData = require('src.gamedata')

local PowerUp = {
  x = 0,
  y = 0,
  z = 30,  -- Float higher than exp orbs
  radius = 20,
  pickupRadius = 50,
  type = "none",
  rarity = 1,  -- Default rarity
  duration = 30,  -- 30 seconds duration
  rotationSpeed = 2,
  angle = 0,
  bobPhase = 0
}

function PowerUp:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function PowerUp:init(x, y, type)
  self.x = x
  self.y = y
  self.type = type
  self.angle = 0
  self.bobPhase = 0
  return self
end

function PowerUp:update(dt)
  -- Rotate the powerup
  self.angle = self.angle + self.rotationSpeed * dt
  
  -- Simple floating animation
  self.bobPhase = (self.bobPhase + dt * 2) % (math.pi * 2)
  self.z = 30 + math.sin(self.bobPhase) * 5
  
  -- Check for player pickup
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  if distance < self.pickupRadius then
    self:applyEffect()
    return true  -- Signal to remove powerup
  end
  
  return false
end

function PowerUp:applyEffect()
  local effect = GameData.POWERUP_TYPES[self.type]
  if not effect then return end
  
  -- Convert type to lowercase to match player's expected format
  local powerUpType = effect.name:lower()
  
  -- Apply the power-up effect to the player
  _G.player:addPowerUp(powerUpType, effect.multiplier, self.duration)
end

return PowerUp


