local Constants = require('src.constants')
local Rune = require('src.rune')
local Projectile = require('src.projectile')

local Player = {
  -- Position and movement
  x = 0,
  y = 0,
  angle = 0,
  moveSpeed = 150,    -- Reduced from 200
  strafeSpeed = 150,  -- Reduced from 300
  turnSpeed = 2.5,
  
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
  baseMoveSpeed = 150,  -- Reduced from 200
  basePickupRange = 50,
  pickupRange = 50,     -- Current pickup range
  
  -- Add rune system
  runes = {},
  runeEffects = {
    experienceMultiplier = 1.0,
    powerDurationMultiplier = 1.0,
    moveSpeedMultiplier = 1.0,
    damageMultiplier = 1.0,
    critChanceBonus = 0,
    fireRateMultiplier = 1.0,
    projectileCount = 0  -- New effect: additional projectiles
  },
  
  -- Add dash properties
  dashSpeed = 400,         -- Reduced from 800 to 400
  dashDuration = 0.25,     -- Increased from 0.15 to 0.25 seconds
  dashCooldown = 1.2,      -- Increased from 0.5 to 1.2 seconds
  isDashing = false,       -- Current dash state
  dashTimer = 0,          -- Current dash duration
  dashCooldownTimer = 0,  -- Current cooldown timer
  dashDirection = {x = 0, y = 0}, -- Store dash direction

  -- Add shooting properties
  baseShootCooldown = 0.6,  -- Reduced from 1.2 (lower cooldown = faster firing)
  shootCooldown = 0.6,      -- Initial cooldown matches base cooldown
  shootTimer = 0,

  -- Add targeting properties
  targetingEnabled = false,  -- Add this line to default targeting to false
  currentTarget = nil,
  targetLockRange = 400,  -- Range to acquire targets
  orbitDistance = 200,    -- Preferred distance to orbit target
  orbitSpeed = 0.8,       -- Base orbit rotation speed

  -- Combat modifiers
  damageMultiplier = 1.0,  -- Base multiplier
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
  self.targetLockRange = 400
  self.orbitDistance = 200
  self.orbitSpeed = 0.8  -- Significantly reduced orbit speed
end

function Player:findTarget()
  if not self.targetingEnabled or not _G.enemies then return nil end
  
  local closestEnemy = nil
  local closestAngle = math.huge
  local closestDist = math.huge
  
  -- Get our forward vector
  local forwardX = math.sin(self.angle)
  local forwardY = math.cos(self.angle)
  
  for _, enemy in ipairs(_G.enemies) do
    -- Calculate vector to enemy
    local dx = enemy.x - self.x
    local dy = enemy.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    -- Only consider enemies within range
    if dist <= self.targetLockRange then
      -- Normalize direction to enemy
      local dirX = dx / dist
      local dirY = dy / dist
      
      -- Calculate dot product with forward vector (gives cosine of angle)
      local dot = dirX * forwardX + dirY * forwardY
      
      -- Convert to angle (in radians)
      local angle = math.acos(dot)
      
      -- If this is the closest enemy within a 60-degree cone in front
      if angle < math.pi/3 and angle < closestAngle then
        closestAngle = angle
        closestDist = dist
        closestEnemy = enemy
      end
    end
  end
  
  return closestEnemy
end

function Player:handleInput()
  -- Don't handle input if dead
  if self.isDead then return end
  
  -- Reset movement state
  self.forward = 0
  self.strafe = 0
  self.rotation = 0
  
  -- Get gamepad (using first connected gamepad)
  local joystick = love.joystick.getJoysticks()[1]
  
  -- Forward/Backward movement (Left stick Y-axis)
  if love.keyboard.isDown('w') or (joystick and joystick:getAxis(2) < -0.25) then
    self.forward = 1
  end
  if love.keyboard.isDown('s') or (joystick and joystick:getAxis(2) > 0.25) then
    self.forward = -1
  end
  
  -- Strafe movement (Left stick X-axis)
  if love.keyboard.isDown('a') or (joystick and joystick:getAxis(1) < -0.25) then
    self.strafe = -1
  end
  if love.keyboard.isDown('d') or (joystick and joystick:getAxis(1) > 0.25) then
    self.strafe = 1
  end
  
  -- Keyboard rotation with Q and E
  if love.keyboard.isDown('q') then
    self.rotation = -1
  elseif love.keyboard.isDown('e') then
    self.rotation = 1
  end
  
  -- Camera rotation (right stick X-axis only)
  if joystick then
    local rightStickX = joystick:getAxis(4)  -- Right stick X axis
    if math.abs(rightStickX) > 0.25 then
      self.rotation = rightStickX
    end
  end
  
  -- Check if shooting (keyboard/mouse or controller)
  local isShooting = love.keyboard.isDown('space') or 
                     love.mouse.isDown(1) or 
                     (joystick and (joystick:isDown(5) or joystick:isDown(6)))  -- RB/RT buttons
  
  if isShooting then
    if self.shootTimer <= 0 then
      self:shoot()
      self.shootTimer = self.shootCooldown
    end
  end
  
  -- Dash (keyboard or controller)
  -- Only initiate dash if not already dashing and cooldown is complete
  if not self.isDashing and self.dashCooldownTimer <= 0 then
    if love.mouse.isDown(2) or (joystick and joystick:isDown(1)) then  -- B button
      -- Calculate movement vector
      local moveX = 0
      local moveY = 0
      
      -- Add forward/backward component
      if self.forward ~= 0 then
        moveX = moveX + math.sin(self.angle) * self.forward
        moveY = moveY + math.cos(self.angle) * self.forward
      end
      
      -- Add strafe component
      if self.strafe ~= 0 then
        moveX = moveX + math.sin(self.angle + math.pi/2) * self.strafe
        moveY = moveY + math.cos(self.angle + math.pi/2) * self.strafe
      end
      
      -- Only dash if there's movement input
      local length = math.sqrt(moveX * moveX + moveY * moveY)
      if length > 0.001 then  -- Small threshold to avoid floating point issues
        -- Normalize the movement vector
        self.dashDirection.x = moveX / length
        self.dashDirection.y = moveY / length
        self.isDashing = true
        self.dashTimer = self.dashDuration
        self.dashCooldownTimer = self.dashCooldown
      end
    end
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
  
  -- Update shoot cooldown
  if self.shootTimer > 0 then
    self.shootTimer = self.shootTimer - dt
  end

  -- Handle shooting with debug prints
  if love.keyboard.isDown('space') then
    print("Space pressed!")  -- Debug print
    if self.shootTimer <= 0 then
      print("Shooting!")  -- Debug print
      self:shoot()
      self.shootTimer = self.shootCooldown
    end
  end

  -- Update dash cooldown timer
  if self.dashCooldownTimer > 0 then
    self.dashCooldownTimer = self.dashCooldownTimer - dt
  end

  -- Store previous position
  self.lastX = self.x
  self.lastY = self.y
  
  -- Handle keyboard input
  self:handleInput()
  
  -- Update rotation
  self.angle = self.angle + (self.rotation * self.turnSpeed * dt)
  
  -- Update dash state
  if self.isDashing then
    self.dashTimer = self.dashTimer - dt
    if self.dashTimer <= 0 then
      self.isDashing = false
      self.dashCooldownTimer = self.dashCooldown  -- Start cooldown when dash ends
    end
    
    -- Move in dash direction
    self.x = self.x + self.dashDirection.x * self.dashSpeed * dt
    self.y = self.y + self.dashDirection.y * self.dashSpeed * dt
  else
    -- Normal movement
    if self.forward ~= 0 or self.strafe ~= 0 then
      -- Calculate movement vector (relative to player's angle)
      local moveX = 0
      local moveY = 0
      
      -- Forward/backward movement (relative to facing direction)
      if self.forward ~= 0 then
        moveX = math.sin(self.angle) * self.forward * self.moveSpeed
        moveY = math.cos(self.angle) * self.forward * self.moveSpeed
      end
      
      -- Strafe movement (perpendicular to facing direction)
      if self.strafe ~= 0 then
        moveX = moveX + math.sin(self.angle + math.pi/2) * self.strafe * self.strafeSpeed
        moveY = moveY + math.cos(self.angle + math.pi/2) * self.strafe * self.strafeSpeed
      end
      
      -- Check for dash input (now using right mouse button)
      if love.mouse.isDown(2) and self.dashCooldownTimer <= 0 then
        -- Normalize direction for dash
        local length = math.sqrt(moveX * moveX + moveY * moveY)
        if length > 0 then
          self.dashDirection.x = moveX / length
          self.dashDirection.y = moveY / length
          self.isDashing = true
          self.dashTimer = self.dashDuration
        end
      else
        -- Normal movement
        self.x = self.x + moveX * dt
        self.y = self.y + moveY * dt
      end
    end
  end
  
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
  -- Apply experience multiplier from runes
  amount = amount * self.runeEffects.experienceMultiplier
  self.experience = self.experience + amount
  
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
  -- Apply power-up duration multiplier from runes
  duration = duration * self.runeEffects.powerDurationMultiplier
  
  table.insert(self.activePowerUps, {
    type = type,
    multiplier = multiplier,
    timeLeft = duration,
    duration = duration
  })
  
  self:updatePowerUpEffects()
end

function Player:updatePowerUpEffects()
  -- Reset to base values
  self.moveSpeed = self.baseMoveSpeed
  self.pickupRange = self.basePickupRange
  self.damageMultiplier = 1.0  -- Reset to base
  
  -- Apply all active power-ups
  for _, powerUp in ipairs(self.activePowerUps) do
    if powerUp.type == "speed" then
      self.moveSpeed = self.moveSpeed * powerUp.multiplier
    elseif powerUp.type == "range" then
      self.pickupRange = self.pickupRange * powerUp.multiplier
    elseif powerUp.type == "damage" then
      self.damageMultiplier = self.damageMultiplier * powerUp.multiplier
    end
  end
end

function Player:addRune(runeType)
  -- Add rune to collection
  table.insert(self.runes, runeType)
  
  -- Apply rune effects
  local effects = Rune.TYPES[runeType].effects
  for stat, multiplier in pairs(effects) do
    if self.runeEffects[stat] then
      if string.find(stat, "Multiplier") then
        -- Multiply effect for multipliers
        self.runeEffects[stat] = self.runeEffects[stat] * multiplier
      else
        -- Add effect for flat bonuses
        self.runeEffects[stat] = self.runeEffects[stat] + multiplier
      end
    end
  end
  
  -- Update player stats
  self:updateStats()
end

function Player:updateStats()
  -- Apply rune effects to base stats
  self.moveSpeed = self.baseMoveSpeed * self.runeEffects.moveSpeedMultiplier
  self.critChance = 0.05 + self.runeEffects.critChanceBonus
  self.shootCooldown = self.baseShootCooldown / self.runeEffects.fireRateMultiplier  -- Lower cooldown = faster firing
end

function Player:shoot()
  local dirVector = _G.camera:getDirectionVector()
  
  -- Base projectile
  _G.spawnProjectile(dirVector.x, dirVector.y)
  
  -- Additional projectiles from runes
  if self.runeEffects.projectileCount > 0 then
    local spreadAngle = math.pi / 8  -- 22.5 degrees spread
    for i = 1, self.runeEffects.projectileCount do
      -- Alternate left and right spread
      local angle = spreadAngle * (i % 2 == 0 and 1 or -1) * math.ceil(i/2)
      local cos = math.cos(angle)
      local sin = math.sin(angle)
      
      -- Rotate the direction vector
      local newDirX = dirVector.x * cos - dirVector.y * sin
      local newDirY = dirVector.x * sin + dirVector.y * cos
      
      _G.spawnProjectile(newDirX, newDirY)
    end
  end
end

-- Add new method to calculate final damage with all modifiers
function Player:calculateDamage(baseDamage)
  local finalMultiplier = self.damageMultiplier
  
  -- Apply rune effects
  finalMultiplier = finalMultiplier * self.runeEffects.damageMultiplier
  
  -- Apply active power-up effects
  for _, powerUp in ipairs(self.activePowerUps) do
    if powerUp.type == "damage" then
      finalMultiplier = finalMultiplier * powerUp.multiplier
    end
  end
  
  return baseDamage * finalMultiplier
end

return Player




































