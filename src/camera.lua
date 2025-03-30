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
  bobActive = false
}

function Camera:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.z = self.baseHeight  -- Initialize z to baseHeight
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
  if player.isDead then
    -- Keep last position and angle when player is dead
    return
  end

  -- Get movement amount for bob effect
  local dx = player.x - player.lastX
  local dy = player.y - player.lastY
  local isMoving = math.abs(dx) > 0.01 or math.abs(dy) > 0.01
  
  -- Update bob effect
  if isMoving then
    self.bobActive = true
    self.bobPhase = (self.bobPhase + dt * self.bobFrequency) % (math.pi * 2)
  else
    self.bobActive = false
    if math.abs(self.bobPhase) > 0.01 then
      self.bobPhase = self.bobPhase * 0.95
    else
      self.bobPhase = 0
    end
  end
  
  -- Calculate bob offset
  local bobOffset = 0
  local angleOffset = 0
  if self.bobActive then
    bobOffset = math.abs(math.sin(self.bobPhase)) * self.bobAmplitude
    angleOffset = math.cos(self.bobPhase) * self.bobAngleAmount
  end
  
  -- Apply bob to camera height
  self.z = self.baseHeight + bobOffset
  
  -- Update camera position to follow player
  self.x = player.x
  self.y = player.y
  self.angle = player.angle + angleOffset
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




