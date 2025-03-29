local Constants = require('src.constants')

local Camera = {
  -- View properties
  z = Constants.CAMERA_HEIGHT,
  baseHeight = Constants.CAMERA_HEIGHT,
  
  -- Bob settings
  bobAmplitude = 6,
  bobFrequency = 4,
  bobAngleAmount = 0.001,
  bobPhase = 0,
  bobActive = false
}

function Camera:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Camera:update(dt, player)
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




