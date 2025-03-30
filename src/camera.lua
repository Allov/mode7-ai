local Constants = require('src.constants')

local Camera = {
  x = 0,
  y = 0,
  z = 0,
  angle = 0,
  baseHeight = Constants.CAMERA_HEIGHT,  -- Set default height from constants
  bobPhase = 0,
  bobFrequency = 8,
  bobAmplitude = 5,
  bobAngleAmount = 0.02,
  bobActive = false,
  -- Add shake properties
  shakeAmount = 0,
  shakeDecay = 5,  -- How fast the shake dies down
  shakeMaxOffset = 20  -- Maximum pixel offset during shake
}

-- Add shake method
function Camera:shake(amount)
  self.shakeAmount = amount
end

function Camera:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.z = self.baseHeight  -- Initialize z to baseHeight
  -- Initialize shake properties
  o.shakeAmount = 0
  o.shakeDecay = 90
  o.shakeMaxOffset = 20
  return o
end

-- Add distanceTo method
function Camera:distanceTo(x, y)
  local dx = self.x - x
  local dy = self.y - y
  return math.sqrt(dx * dx + dy * dy)
end

function Camera:reset()
  self.x = 0
  self.y = 0
  self.z = self.baseHeight
  self.angle = 0
  self.bobPhase = 0
  self.bobActive = false
end

function Camera:update(dt, player)
  if player.isDead then return end

  -- Update shake with stronger effect
  if self.shakeAmount > 0 then
    self.shakeAmount = math.max(0, self.shakeAmount - self.shakeDecay * dt)
    
    -- Apply shake offset
    local shakePower = self.shakeAmount / 100
    self.x = player.x + (math.random() - 0.5) * self.shakeMaxOffset * shakePower
    self.y = player.y + (math.random() - 0.5) * self.shakeMaxOffset * shakePower
    self.angle = player.angle + (math.random() - 0.5) * 0.2 * shakePower  -- Increased angle shake
  else
    -- No shake, just follow player
    self.x = player.x
    self.y = player.y
    self.angle = player.angle
  end

  -- Handle bob effect
  local dx = player.x - player.lastX
  local dy = player.y - player.lastY
  local isMoving = math.abs(dx) > 0.01 or math.abs(dy) > 0.01
  
  if isMoving then
    self.bobActive = true
    self.bobPhase = (self.bobPhase + dt * self.bobFrequency) % (math.pi * 2)
  else
    self.bobActive = false
    self.bobPhase = self.bobPhase * 0.95
  end
  
  -- Apply bob effect to height
  if self.bobActive then
    self.z = self.baseHeight + math.sin(self.bobPhase) * self.bobAmplitude
  else
    self.z = self.baseHeight
  end
end

-- Helper function to get camera direction vector
function Camera:getDirectionVector()
  return {
    x = math.sin(self.angle),  -- Changed from cos to sin
    y = math.cos(self.angle)   -- Changed from sin to cos
  }
end

-- Helper function to get camera right vector (perpendicular to direction)
function Camera:getRightVector()
  return {
    x = math.sin(self.angle + math.pi/2),  -- Changed to match the direction vector pattern
    y = math.cos(self.angle + math.pi/2)   -- Changed to match the direction vector pattern
  }
end

return Camera




