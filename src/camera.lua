local Constants = require('src.constants')

local Camera = {
  x = 0,
  y = 0,
  z = Constants.CAMERA_HEIGHT,
  baseHeight = Constants.CAMERA_HEIGHT,
  angle = 0,
  
  -- Movement settings (reduced speeds)
  moveSpeed = 200,     -- Reduced from 200
  strafeSpeed = 300,   -- Reduced from 150
  turnSpeed = 3.0,     -- Reduced from 3
  
  -- Bob settings (reduced values)
  bobAmplitude = 6,    -- Reduced from 5
  bobFrequency = 4,    -- Reduced from 5
  bobAngleAmount = 0.001, -- Reduced from 0.02
  bobPhase = 0,
  bobActive = false,
  lastX = 0,
  lastY = 0,
  
  -- Movement state
  forward = 0,
  strafe = 0,
  rotation = 0
}

function Camera:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.lastX = o.x
  o.lastY = o.y
  return o
end

function Camera:handleInput()
  -- Reset movement state
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
  
  -- Forward/Backward (W/S)
  if love.keyboard.isDown('w') then
    self.forward = 1  -- Forward is positive
  end
  if love.keyboard.isDown('s') then
    self.forward = -1  -- Backward is negative
  end
  
  -- Strafe Left/Right (A/D)
  if love.keyboard.isDown('a') then
    self.strafe = 1  -- Left is positive
  end
  if love.keyboard.isDown('d') then
    self.strafe = -1  -- Right is negative
  end
  
  -- Rotation (Q/E or Left/Right arrows)
  if love.keyboard.isDown('q') or love.keyboard.isDown('left') then
    self.rotation = -1  -- Left rotation is negative
  end
  if love.keyboard.isDown('e') or love.keyboard.isDown('right') then
    self.rotation = 1  -- Right rotation is positive
  end
end

function Camera:update(dt)
  -- Store previous position
  self.lastX = self.x
  self.lastY = self.y
  
  -- Handle keyboard input
  self:handleInput()
  
  -- Update rotation
  self.angle = self.angle + (self.rotation * self.turnSpeed * dt)
  
  -- Calculate forward and sideways movement vectors
  local forwardX = math.sin(self.angle)
  local forwardY = math.cos(self.angle)
  local strafeX = math.sin(self.angle - math.pi/2)
  local strafeY = math.cos(self.angle - math.pi/2)
  
  -- Apply forward/backward movement
  self.x = self.x + (forwardX * self.forward * self.moveSpeed * dt)
  self.y = self.y + (forwardY * self.forward * self.moveSpeed * dt)
  
  -- Apply strafe movement
  self.x = self.x + (strafeX * self.strafe * self.strafeSpeed * dt)
  self.y = self.y + (strafeY * self.strafe * self.strafeSpeed * dt)
  
  -- Check if camera is moving
  local dx = self.x - self.lastX
  local dy = self.y - self.lastY
  local isMoving = math.abs(dx) > 0.01 or math.abs(dy) > 0.01  -- More sensitive movement detection
  
  -- Update bob effect
  if isMoving then
    self.bobActive = true
    self.bobPhase = (self.bobPhase + dt * self.bobFrequency) % (math.pi * 2)
  else
    -- Gradually return to center when not moving
    self.bobActive = false
    if math.abs(self.bobPhase) > 0.01 then
      self.bobPhase = self.bobPhase * 0.95  -- Smooth return to center
    else
      self.bobPhase = 0
    end
  end
  
  -- Calculate bob offset
  local bobOffset = 0
  local angleOffset = 0
  if self.bobActive then
    -- Use absolute sine wave for more pronounced up/down motion
    bobOffset = math.abs(math.sin(self.bobPhase)) * self.bobAmplitude
    angleOffset = math.cos(self.bobPhase) * self.bobAngleAmount
  end
  
  -- Apply bob to camera height and angle
  self.z = self.baseHeight + bobOffset  -- Changed: - to + to fix inverted bobbing
  self.angle = self.angle + angleOffset
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




