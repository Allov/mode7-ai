local Constants = require('src.constants')

local Camera = {
  x = 0,
  y = 0,
  z = Constants.CAMERA_HEIGHT,  -- Initialize z to base height
  angle = 0,
  baseHeight = Constants.CAMERA_HEIGHT,
  bobPhase = 0,
  bobFrequency = 16,      -- Fast enough to match running/walking
  bobAmplitude = 4,      -- Larger amplitude for noticeable effect in Mode7
  bobSideAmount = 3,      -- Side-to-side movement
  bobActive = false,
  shakeAmount = 0,
  shakeDecay = 5,
  shakeMaxOffset = 20
}

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

  -- Base position follows player
  self.x = player.x
  self.y = player.y
  self.angle = player.angle

  -- Head bob effect based on movement
  local isMoving = math.abs(player.forward) > 0.01 or math.abs(player.strafe) > 0.01
  
  if isMoving then
    self.bobPhase = (self.bobPhase + dt * self.bobFrequency) % (math.pi * 2)
    
    -- Update camera height with bobbing
    self.z = self.baseHeight + math.sin(self.bobPhase) * self.bobAmplitude
    
    -- Horizontal movement (side to side)
    local sideOffset = math.cos(self.bobPhase) * self.bobSideAmount
    local dirVector = self:getRightVector()
    self.x = self.x + dirVector.x * sideOffset
    self.y = self.y + dirVector.y * sideOffset
  else
    -- Smoothly return to base height when not moving
    self.z = self.baseHeight
  end

  -- Handle shake effect
  if self.shakeAmount > 0 then
    self.shakeAmount = math.max(0, self.shakeAmount - self.shakeDecay * dt)
    local shakePower = self.shakeAmount / 100
    self.x = self.x + (math.random() - 0.5) * self.shakeMaxOffset * shakePower
    self.y = self.y + (math.random() - 0.5) * self.shakeMaxOffset * shakePower
    self.angle = self.angle + (math.random() - 0.5) * 0.2 * shakePower
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




