local Constants = require('src.constants')

local Projectile = {
  x = 0,
  y = 0,
  z = 0,  -- Add z coordinate for height
  angle = 0,
  speed = 500,  -- Projectile speed (pixels per second)
  lifetime = 2, -- How long the projectile lives (seconds)
  age = 0      -- Current age of projectile
}

function Projectile:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Projectile:init(x, y, angle, height)
  self.x = x
  self.y = y
  self.z = height or Constants.CAMERA_HEIGHT  -- Use passed height or default
  self.angle = angle
  self.age = 0
  return self
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


