local Constants = require('src.constants')

local Player = {
  -- Position and movement
  x = 0,
  y = 0,
  angle = 0,
  moveSpeed = 200,
  strafeSpeed = 300,
  turnSpeed = 3.0,
  
  -- Combat properties
  health = 100,
  maxHealth = 100,
  invulnerableTime = 1.0,
  invulnerableTimer = 0,
  isDead = false,
  
  -- Movement state
  forward = 0,
  strafe = 0,
  rotation = 0,
  
  -- Store last position for movement detection
  lastX = 0,
  lastY = 0,
  
  -- Add game over state
  deathTimer = 0,
  deathAnimationTime = 2.0,  -- Time for death animation/transition
  
  -- Experience system
  experience = 0,
  level = 1,
  experienceToNextLevel = 100,  -- Base XP needed
  
  -- Add power-up related properties
  activePowerUps = {},  -- Stores active power-ups
  baseMoveSpeed = 200,  -- Store base values
  baseDamage = 25,
  basePickupRange = 50,
  pickupRange = 50,     -- Current pickup range
}

function Player:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.lastX = o.x
  o.lastY = o.y
  o.activePowerUps = {}  -- Initialize power-ups table
  return o
end

function Player:reset()
  self.x = 0
  self.y = 0
  self.angle = 0
  self.health = self.maxHealth
  self.invulnerableTimer = 0
  self.isDead = false
  self.deathTimer = 0
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
  self.lastX = 0  -- Reset last position
  self.lastY = 0
end

function Player:handleInput()
  -- Don't handle input if dead
  if self.isDead then return end
  
  -- Reset movement state
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
  
  -- Forward/Backward (W/S)
  if love.keyboard.isDown('w') then
    self.forward = 1
  end
  if love.keyboard.isDown('s') then
    self.forward = -1
  end
  
  -- Strafe Left/Right (A/D)
  if love.keyboard.isDown('a') then
    self.strafe = 1
  end
  if love.keyboard.isDown('d') then
    self.strafe = -1
  end
  
  -- Rotation (Q/E or Left/Right arrows)
  if love.keyboard.isDown('q') or love.keyboard.isDown('left') then
    self.rotation = -1
  end
  if love.keyboard.isDown('e') or love.keyboard.isDown('right') then
    self.rotation = 1
  end
end

function Player:takeDamage(amount)
  if self.invulnerableTimer > 0 or self.isDead then return false end
  
  self.health = math.max(0, self.health - amount)
  self.invulnerableTimer = self.invulnerableTime
  
  if self.health <= 0 then
    self:die()
  end
  
  return true
end

function Player:die()
  self.isDead = true
  self.deathTimer = self.deathAnimationTime
  -- Stop all movement
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
end

function Player:update(dt)
  if self.isDead then
    self.deathTimer = math.max(0, self.deathTimer - dt)
    return
  end
  
  -- Update invulnerability timer
  if self.invulnerableTimer > 0 then
    self.invulnerableTimer = math.max(0, self.invulnerableTimer - dt)
  end
  
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
  
  -- Update power-ups
  for i = #self.activePowerUps, 1, -1 do
    local powerUp = self.activePowerUps[i]
    powerUp.timeLeft = powerUp.timeLeft - dt
    
    if powerUp.timeLeft <= 0 then
      table.remove(self.activePowerUps, i)
      self:updatePowerUpEffects()  -- Recalculate effects when power-up expires
    end
  end
end

-- Helper function to get direction vector
function Player:getDirectionVector()
  return {
    x = math.sin(self.angle),
    y = math.cos(self.angle)
  }
end

function Player:gainExperience(amount)
  self.experience = self.experience + amount
  
  -- Check for level up
  while self.experience >= self.experienceToNextLevel do
    self:levelUp()
  end
end

function Player:levelUp()
  self.level = self.level + 1
  self.experience = self.experience - self.experienceToNextLevel
  -- Increase XP needed for next level (by 50%)
  self.experienceToNextLevel = math.floor(self.experienceToNextLevel * 1.5)
  
  -- Could add level-up benefits here
  self.maxHealth = self.maxHealth + 10
  self.health = self.maxHealth
end

function Player:addPowerUp(type, multiplier, duration)
  -- Debug print to verify power-up is being added
  print("Adding power-up:", type, multiplier, duration)
  
  table.insert(self.activePowerUps, {
    type = type,
    multiplier = multiplier,
    timeLeft = duration,
    duration = duration  -- Store initial duration for UI
  })
  
  -- Immediately apply effects
  self:updatePowerUpEffects()
end

function Player:updatePowerUpEffects()
  -- Reset to base values
  self.moveSpeed = self.baseMoveSpeed
  self.pickupRange = self.basePickupRange
  
  -- Apply all active power-ups
  for _, powerUp in ipairs(self.activePowerUps) do
    if powerUp.type == "speed" then
      self.moveSpeed = self.moveSpeed * powerUp.multiplier
    elseif powerUp.type == "range" then
      self.pickupRange = self.pickupRange * powerUp.multiplier
    elseif powerUp.type == "damage" then
      -- Update damage
      self.baseDamage = self.baseDamage * powerUp.multiplier
    end
  end
end

return Player






