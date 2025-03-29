local Constants = require('src.constants')

local ExperienceOrb = {
  x = 0,
  y = 0,
  z = 0,
  value = 10,
  radius = 15,
  pickupRadius = 50,      -- Distance at which player can collect
  magnetRadius = 150,     -- Distance at which orbs start flying to player
  maxSpeed = 500,        -- Maximum flight speed
  acceleration = 1000,   -- How quickly orb accelerates toward player
  velocityX = 0,
  velocityY = 0,
  age = 0,
  lifetime = 20.0,       -- Orbs disappear after 20 seconds
  bobHeight = 10,        -- How high it bobs up and down
  bobSpeed = 2,          -- Speed of bobbing motion
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
  
  -- Bob up and down
  self.z = self.bobHeight * math.sin(self.age * self.bobSpeed)
  
  -- Check if expired
  if self.age >= self.lifetime then
    return true
  end
  
  -- Calculate distance to player
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  -- Check for pickup
  if distance < self.pickupRadius then
    _G.player:gainExperience(self.value)
    return true
  end
  
  -- Magnetic effect when within range
  if distance < self.magnetRadius then
    -- Calculate direction to player
    local dirX = dx / distance
    local dirY = dy / distance
    
    -- Accelerate toward player
    local acceleration = self.acceleration * (1 - distance / self.magnetRadius)
    self.velocityX = self.velocityX + dirX * acceleration * dt
    self.velocityY = self.velocityY + dirY * acceleration * dt
    
    -- Limit speed
    local currentSpeed = math.sqrt(self.velocityX * self.velocityX + self.velocityY * self.velocityY)
    if currentSpeed > self.maxSpeed then
      local scale = self.maxSpeed / currentSpeed
      self.velocityX = self.velocityX * scale
      self.velocityY = self.velocityY * scale
    end
  else
    -- Slow down when out of range
    self.velocityX = self.velocityX * 0.95
    self.velocityY = self.velocityY * 0.95
  end
  
  -- Update position
  self.x = self.x + self.velocityX * dt
  self.y = self.y + self.velocityY * dt
  
  return false
end

return ExperienceOrb
