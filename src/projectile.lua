local Constants = require('src.constants')

local Projectile = {
  x = 0,
  y = 0,
  z = 0,
  angle = 0,
  speed = 500,
  lifetime = 2.0,
  age = 0,
  radius = 5,
  baseDamage = 50,    -- Doubled from 25
  critChance = 0.2,   -- 20% chance to crit
  critMultiplier = 2.0 -- Double damage on crit
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
  self.z = height or Constants.CAMERA_HEIGHT
  self.angle = angle
  self.age = 0
  -- Remove damage multiplier here as we'll calculate it during collision
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
  -- Update position based on angle and speed
  -- Match the camera's coordinate system
  self.x = self.x + math.sin(self.angle) * self.speed * dt
  self.y = self.y + math.cos(self.angle) * self.speed * dt
  
  -- Update lifetime
  self.age = self.age + dt
  
  -- Return true if projectile should be removed
  return self.age >= self.lifetime
end

return Projectile













