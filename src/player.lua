local Constants = require('src.constants')
local Rune = require('src.rune')
local Projectile = require('src.projectile')

local Player = {
  -- Position and movement
  x = 0,
  y = 0,
  angle = 0,
  moveSpeed = 200,
  strafeSpeed = 300,
  turnSpeed = 3.0,mm,
  
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
  
  -- Add rune system
  runes = {},
  runeEffects = {
    experienceMultiplier = 1.0,
    powerDurationMultiplier = 1.0,
    moveSpeedMultiplier = 1.0,
    damageMultiplier = 1.0,
    critChanceBonus = 0,
    fireRateMultiplier = 1.0  -- New effect
  },
  
  -- Add dash properties
  dashSpeed = 800,         -- Speed multiplier during dash
  dashDuration = 0.15,     -- How long the dash lasts in seconds
  dashCooldown = 0.5,      -- Time between dashes
  isDashing = false,       -- Current dash state
  dashTimer = 0,          -- Current dash duration
  dashCooldownTimer = 0,  -- Current cooldown timer
  dashDirection = {x = 0, y = 0}, -- Store dash direction

  -- Add shooting properties
  baseShootCooldown = 1.2,  -- Significantly increased base cooldown (much slower fire rate)
  shootCooldown = 1.2,      -- Current cooldown (affected by power-ups/runes)
  shootTimer = 0,

  -- Add targeting properties
  currentTarget = nil,
  targetLockRange = 400,  -- Range to acquire targets
  orbitDistance = 200,    -- Preferred distance to orbit target
  orbitSpeed = 3.0,       -- Base orbit rotation speed
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

function Player:findTarget()
  if not _G.enemies then return nil end
  
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
  
  -- Forward/Backward (W/S)
  if love.keyboard.isDown('w') then
    self.forward = 1
  end
  if love.keyboard.isDown('s') then
    self.forward = -1
  end
  
  -- Check if shooting
  local isShooting = love.keyboard.isDown('space') or love.mouse.isDown(1)
  
  if isShooting then
    -- Try to acquire target when shooting starts
    if not self.currentTarget then
      self.currentTarget = self:findTarget()
    end
    
    if self.currentTarget then
      -- Calculate vector to target
      local dx = self.currentTarget.x - self.x
      local dy = self.currentTarget.y - self.y
      local dist = math.sqrt(dx * dx + dy * dy)
      
      -- If target gets too far, lose lock
      if dist > self.targetLockRange then
        self.currentTarget = nil
      else
        -- Calculate desired angle to target
        local targetAngle = math.atan2(dy, dx)  -- Changed order to dy, dx
        self.angle = targetAngle
        
        -- Handle orbital movement
        if love.keyboard.isDown('a') or love.keyboard.isDown('q') then
          self.rotation = -1
          -- Orbit counterclockwise
          local targetDist = math.max(dist, self.orbitDistance)
          local orbitAngle = targetAngle - self.orbitSpeed * love.timer.getDelta()
          self.x = self.currentTarget.x + math.cos(orbitAngle) * targetDist  -- Use cos for x
          self.y = self.currentTarget.y + math.sin(orbitAngle) * targetDist  -- Use sin for y
        elseif love.keyboard.isDown('d') or love.keyboard.isDown('e') then
          self.rotation = 1
          -- Orbit clockwise
          local targetDist = math.max(dist, self.orbitDistance)
          local orbitAngle = targetAngle + self.orbitSpeed * love.timer.getDelta()
          self.x = self.currentTarget.x + math.cos(orbitAngle) * targetDist  -- Use cos for x
          self.y = self.currentTarget.y + math.sin(orbitAngle) * targetDist  -- Use sin for y
        end
      end
    else
      -- No target locked, handle normal rotation
      if love.keyboard.isDown('a') or love.keyboard.isDown('q') then
        self.rotation = -1
      elseif love.keyboard.isDown('d') or love.keyboard.isDown('e') then
        self.rotation = 1
      end
    end
  else
    -- Reset target when not shooting
    self.currentTarget = nil
    
    -- Normal strafing movement when not shooting
    if love.keyboard.isDown('a') then
      self.strafe = -1
    end
    if love.keyboard.isDown('d') then
      self.strafe = 1
    end
    
    -- Normal rotation for Q/E
    if love.keyboard.isDown('q') or love.keyboard.isDown('left') then
      self.rotation = -1
    end
    if love.keyboard.isDown('e') or love.keyboard.isDown('right') then
      self.rotation = 1
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
  _G.spawnProjectile(dirVector.x, dirVector.y)
end

return Player



































