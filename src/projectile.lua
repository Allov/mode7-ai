local Constants = require('src.constants')

local Projectile = {
  x = 0,
  y = 0,
  z = 0,
  angle = 0,
  baseSpeed = 300,    -- Initial speed
  speed = nil,        -- Current speed (will be set in init)
  maxSpeed = 800,     -- Maximum speed
  acceleration = 1200, -- Speed increase per second
  lifetime = 2.0,
  age = 0,
  radius = 15,        -- Increased from 5 to 15
  baseDamage = 50,
  critChance = 0.2,
  critMultiplier = 2.0,
  
  -- Drop properties
  dropStartTime = 0,  -- Will be set to 75% of lifetime
  dropSpeed = 400,    -- Increased from 200 to 400 units per second
  initialHeight = 0   -- Will store initial z value
}

-- Helper function to get distance to another position
function Projectile:distanceTo(x, y)
  local dx = self.x - x
  local dy = self.y - y
  return math.sqrt(dx * dx + dy * dy)
end

function Projectile:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Projectile:init(x, y, angle, height)
  self.x = x
  self.y = y
  self.z = height or Constants.CAMERA_HEIGHT - 20  -- Start slightly below camera
  self.initialHeight = self.z
  self.angle = angle
  self.age = 0
  self.speed = self.baseSpeed  -- Make sure speed starts at baseSpeed
  self.dropStartTime = self.lifetime * 0.75
  return self
end

-- Add collision check method
function Projectile:checkCollision(enemy, camera)
  local dx = self.x - enemy.x
  local dy = self.y - enemy.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  -- Scale enemy radius based on distance from camera
  local MIN_RENDER_DISTANCE = 50
  local distanceFromCamera = math.max(enemy:distanceTo(camera.x, camera.y), MIN_RENDER_DISTANCE)
  local scaleMultiplier = Constants.CAMERA_HEIGHT / distanceFromCamera
  local scaledEnemyRadius = enemy.radius * scaleMultiplier * 6.0
  
  if distance < (self.radius + scaledEnemyRadius) then
    -- Let the player calculate final damage with all modifiers
    local finalDamage = _G.player:calculateDamage(self.baseDamage)
    local isCritical = math.random() < self.critChance
    if isCritical then
      finalDamage = finalDamage * self.critMultiplier
    end
    
    enemy:hit(finalDamage, isCritical)
    return true
  end
  
  return false
end

function Projectile:update(dt)
  -- Accelerate more noticeably
  self.speed = math.min(self.speed + self.acceleration * dt, self.maxSpeed)
  
  -- Update position based on angle and speed
  self.x = self.x + math.sin(self.angle) * self.speed * dt
  self.y = self.y + math.cos(self.angle) * self.speed * dt
  
  -- Update lifetime
  self.age = self.age + dt
  
  -- Handle dropping effect after 75% of lifetime
  if self.age >= self.dropStartTime then
    local dropProgress = (self.age - self.dropStartTime) / (self.lifetime - self.dropStartTime)
    -- Use quadratic easing for more natural drop
    local dropAmount = dropProgress * dropProgress * self.dropSpeed
    self.z = math.max(0, self.initialHeight - dropAmount)
  end
  
  -- Return true if projectile should be removed
  return self.age >= self.lifetime
end

return Projectile




















