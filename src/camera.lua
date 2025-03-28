local Camera = {
  x = 0,
  y = 0,
  z = 100,  -- height
  angle = 0,
  
  -- Movement settings
  moveSpeed = 200,    -- Base movement speed
  strafeSpeed = 150,  -- Sideways movement speed
  turnSpeed = 3,      -- Rotation speed in radians per second
  
  -- Movement state
  forward = 0,    -- -1 to 1
  strafe = 0,     -- -1 to 1
  rotation = 0    -- -1 to 1
}

function Camera:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Camera:handleInput()
  -- Reset movement state
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
  
  -- Forward/Backward (W/S)
  if love.keyboard.isDown('w') then
    self.forward = 1  -- Move forward (negative Z)
  end
  if love.keyboard.isDown('s') then
    self.forward = -1   -- Move backward (positive Z)
  end
  
  -- Strafe Left/Right (A/D)
  if love.keyboard.isDown('a') then
    self.strafe = 1  -- Strafe left
  end
  if love.keyboard.isDown('d') then
    self.strafe = -1   -- Strafe right
  end
  
  -- Rotation (Q/E or Left/Right arrows)
  if love.keyboard.isDown('q') or love.keyboard.isDown('left') then
    self.rotation = 1
  end
  if love.keyboard.isDown('e') or love.keyboard.isDown('right') then
    self.rotation = -1
  end
end

function Camera:update(dt)
  -- Handle keyboard input
  self:handleInput()
  
  -- Update rotation
  self.angle = self.angle + (self.rotation * self.turnSpeed * dt)
  
  -- Calculate forward and sideways movement vectors
  local forwardX = -math.sin(self.angle)  -- Changed cos to -sin
  local forwardY = math.cos(self.angle)   -- Changed sin to cos
  local strafeX = -math.cos(self.angle)   -- Changed to -cos
  local strafeY = -math.sin(self.angle)   -- Changed to -sin
  
  -- Apply forward/backward movement
  self.x = self.x + (forwardX * self.forward * self.moveSpeed * dt)
  self.y = self.y + (forwardY * self.forward * self.moveSpeed * dt)
  
  -- Apply strafe movement
  self.x = self.x + (strafeX * self.strafe * self.strafeSpeed * dt)
  self.y = self.y + (strafeY * self.strafe * self.strafeSpeed * dt)
end

-- Helper function to get camera direction vector
function Camera:getDirectionVector()
  return {
    x = math.cos(self.angle),
    y = math.sin(self.angle)
  }
end

-- Helper function to get camera right vector (perpendicular to direction)
function Camera:getRightVector()
  return {
    x = math.cos(self.angle + math.pi/2),
    y = math.sin(self.angle + math.pi/2)
  }
end

return Camera



