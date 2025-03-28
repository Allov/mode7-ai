local Constants = require('src.constants')

local Enemy = {
  x = 0,
  y = 0,
  angle = 0,
  speed = 50,
  turnSpeed = 1,
  
  -- AI state
  isMoving = true,  -- New property to control if enemy moves
  thinkTime = 0,
  thinkInterval = 2, -- Time between direction changes
  targetAngle = 0
}

function Enemy:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Enemy:init(x, y, isMoving)
  self.x = x
  self.y = y
  self.angle = math.random() * math.pi * 2
  self.targetAngle = self.angle
  self.isMoving = isMoving or false  -- Default to standing still
  return self
end

function Enemy:update(dt)
  if not self.isMoving then return end  -- Skip movement logic if standing still
  
  -- Update AI thinking
  self.thinkTime = self.thinkTime + dt
  if self.thinkTime >= self.thinkInterval then
    self.thinkTime = 0
    -- Choose a new random direction
    self.targetAngle = math.random() * math.pi * 2
  end
  
  -- Smoothly rotate towards target angle
  local angleDiff = (self.targetAngle - self.angle)
  -- Normalize angle difference to [-pi, pi]
  angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi
  
  self.angle = self.angle + math.sign(angleDiff) * 
               math.min(self.turnSpeed * dt, math.abs(angleDiff))
  
  -- Move forward (matching camera's coordinate system)
  self.x = self.x + math.sin(self.angle) * self.speed * dt
  self.y = self.y + math.cos(self.angle) * self.speed * dt
  
  -- Keep within bounds (optional)
  local bound = 1000
  self.x = math.clamp(self.x, -bound, bound)
  self.y = math.clamp(self.y, -bound, bound)
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

return Enemy

