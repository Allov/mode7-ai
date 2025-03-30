local Constants = require('src.constants')
local DamageNumber = require('src.damagenumber')

local Enemy = {
  x = 0,
  y = 0,
  angle = 0,
  speed = 50,
  turnSpeed = 1,
  radius = 8,  -- Reduced from 15 to match new 50% smaller size
  isMoving = true,
  thinkTime = 0,
  thinkInterval = 2,
  targetAngle = 0,
  health = 100,
  damageAmount = 20,
  damageRadius = 50,  -- How close enemy needs to be to damage player
  damageNumber = nil,  -- Single damage number instead of array
  experienceValue = 25,
  dropChance = 0.75,  -- 75% chance to drop exp orb
  
  -- Elite properties
  isElite = false,
  eliteMultiplier = 2.5,  -- Elite enemies are 2.5x stronger
  eliteScale = 1.5,       -- Elite enemies are 50% larger
  eliteColor = {1, 0.5, 0, 1}  -- Orange color for elite enemies
}

function Enemy:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Enemy:init(x, y, makeElite)
  self.x = x
  self.y = y
  self.angle = math.random() * math.pi * 2
  
  -- Make elite if specified
  if makeElite then
    self.isElite = true
    self.health = self.health * self.eliteMultiplier
    self.damageAmount = self.damageAmount * 1.5
    self.radius = self.radius * self.eliteScale
    self.experienceValue = math.floor(self.experienceValue * self.eliteMultiplier)
    self.dropChance = 1.0  -- Elite enemies always drop exp
  end
  
  return self
end

function Enemy:update(dt)
  if not self.isMoving then return end  -- Skip movement logic if standing still
  
  -- Update damage number if it exists
  if self.damageNumber then
    self.damageNumber.age = self.damageNumber.age + dt
    
    -- Float upward
    self.damageNumber.z = Constants.CAMERA_HEIGHT - 10 + 
                         (self.damageNumber.floatSpeed * self.damageNumber.age)
    
    -- Remove old damage number
    if self.damageNumber.age >= self.damageNumber.lifetime then
      self.damageNumber = nil
    end
  end
  
  -- Get direction to player
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  
  -- Calculate angle to player
  self.targetAngle = math.atan2(dx, dy)
  
  -- Smoothly rotate towards target angle
  local angleDiff = (self.targetAngle - self.angle)
  -- Normalize angle difference to [-pi, pi]
  angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi
  
  self.angle = self.angle + math.sign(angleDiff) * 
               math.min(self.turnSpeed * dt, math.abs(angleDiff))
  
  -- Move forward (matching camera's coordinate system)
  self.x = self.x + math.sin(self.angle) * self.speed * dt
  self.y = self.y + math.cos(self.angle) * self.speed * dt
  
  -- Check for collision with player
  local distanceToPlayer = math.sqrt(dx * dx + dy * dy)
  
  if distanceToPlayer < self.damageRadius then
    if _G.player:takeDamage(self.damageAmount) then
      -- Optional: knock player back
      local knockbackForce = 100
      _G.player.x = _G.player.x + (dx / distanceToPlayer) * knockbackForce * dt
      _G.player.y = _G.player.y + (dy / distanceToPlayer) * knockbackForce * dt
    end
  end
end

-- Helper function to get distance to another position
function Enemy:distanceTo(x, y)
  local dx = self.x - x
  local dy = self.y - y
  return math.sqrt(dx * dx + dy * dy)
end

-- Add these helper functions
function math.sign(x)
  return x > 0 and 1 or (x < 0 and -1 or 0)
end

function math.clamp(x, min, max)
  return math.min(math.max(x, min), max)
end

-- Add hit method with damage numbers
function Enemy:hit(damage, isCritical)
  self.health = self.health - damage
  
  -- Create damage number
  self.damageNumber = DamageNumber:new({
    value = damage,
    x = self.x,
    y = self.y,
    z = Constants.CAMERA_HEIGHT - 10,
    baseScale = isCritical and 1.5 or 1.0,
    isCritical = isCritical
  })
  
  local isDead = self.health <= 0
  
  if isDead and math.random() < self.dropChance then
    self.shouldDropExp = true
  end
  
  return isDead
end

return Enemy





















