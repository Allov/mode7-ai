local Constants = require('src.constants')

local ExperienceOrb = {
  x = 0,
  y = 0,
  z = 20,  -- Float above ground
  value = 10,
  radius = 15,
  magnetRadius = 150,     -- Distance at which orbs start flying to player
  maxSpeed = 500,        -- Maximum flight speed
  acceleration = 1000,   -- How quickly orb accelerates toward player
  velocityX = 0,
  velocityY = 0,
  age = 0,
  lifetime = 20.0       -- Orbs disappear after 20 seconds
}

function ExperienceOrb:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function ExperienceOrb:init(x, y, value)
  self.x = x
  self.y = y
  self.z = 0
  self.value = value or 10
  self.age = 0
  self.velocityX = 0
  self.velocityY = 0
  return self
end

function ExperienceOrb:update(dt)
  self.age = self.age + dt
  
  -- Check if expired
  if self.age >= self.lifetime then
    print("Exp orb expired") -- Debug print
    return true
  end
  
  -- Calculate distance to player
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  -- Check for pickup
  if distance < _G.player.pickupRange then
    _G.player:gainExperience(self.value)
    print("Exp orb collected, value: " .. self.value) -- Debug print
    return true
  end
  
  -- Move towards player when in range
  if distance < self.magnetRadius then
    local angle = math.atan2(dy, dx)
    local acceleration = self.acceleration * dt
    
    self.velocityX = self.velocityX + math.cos(angle) * acceleration
    self.velocityY = self.velocityY + math.sin(angle) * acceleration
    
    -- Limit speed
    local currentSpeed = math.sqrt(self.velocityX * self.velocityX + self.velocityY * self.velocityY)
    if currentSpeed > self.maxSpeed then
      local scale = self.maxSpeed / currentSpeed
      self.velocityX = self.velocityX * scale
      self.velocityY = self.velocityY * scale
    end
  end
  
  -- Update position
  self.x = self.x + self.velocityX * dt
  self.y = self.y + self.velocityY * dt
  
  return false
end

-- Add if not already present
function ExperienceOrb:distanceTo(x, y)
  local dx = self.x - x
  local dy = self.y - y
  return math.sqrt(dx * dx + dy * dy)
end

return ExperienceOrb





