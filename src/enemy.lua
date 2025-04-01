local Constants = require('src.constants')
local DamageNumber = require('src.damagenumber')  -- Make sure path # correct
local FrostOrb = require('src.orbs.frost')  -- Add this at the top with other requires

local Enemy = {
  x = 0,
  y = 0,
  angle = 0,
  speed = 50,
  turnSpeed = 1,
  radius = 8,  -- Reduced from 15 to match new 50% smaller size
  isMoving = true,
  thinkTime = 0,
  thinkInterval = 2,
  targetAngle = 0,
  health = 200,        -- Increased from 100 to 200
  maxHealth = 200,     -- Add maxHealth property
  damageAmount = 20,
  damageRadius = 50,  -- How close enemy needs to be to damage player
  damageNumber = nil,  -- Single damage number instead of array
  experienceValue = 25,
  dropChance = 0.75,  -- 75% chance to drop exp orb
  isDead = false,  -- Add this flag
  shouldDropExp = true,  -- Add this flag
  isBuffed = false,
  baseSpeed = 50,     -- Store base speed
  slowEffects = {},   -- Track active slows
  
  -- Elite properties
  isElite = false,
  eliteMultiplier = 2.5,  -- Elite enemies are 2.5x stronger
  eliteScale = 1.5,       -- Elite enemies are 50% larger
  eliteColor = {1, 0.5, 0, 1}  -- Orange color for elite enemies
}

function Enemy:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  
  -- Set initial health and maxHealth BEFORE applying elite multiplier
  o.maxHealth = o.health  -- Set maxHealth to match initial health
  
  -- Apply elite multiplier if needed
  if o.isElite then
    o.health = o.health * o.eliteMultiplier
    o.maxHealth = o.maxHealth * o.eliteMultiplier
    o.damageAmount = o.damageAmount * 1.5
    o.radius = o.radius * o.eliteScale
    o.experienceValue = math.floor(o.experienceValue * o.eliteMultiplier)
    o.dropChance = 1.0  -- Elite enemies always drop exp
  end
  
  return o
end

function Enemy:init(x, y, makeElite)
  self.x = x
  self.y = y
  self.angle = math.random() * math.pi * 2
  
  -- Make elite if specified
  if makeElite then
    self.isElite = true
    self.health = self.health * self.eliteMultiplier
    self.maxHealth = self.maxHealth * self.eliteMultiplier
    self.damageAmount = self.damageAmount * 1.5
    self.radius = self.radius * self.eliteScale
    self.experienceValue = math.floor(self.experienceValue * self.eliteMultiplier)
    self.dropChance = 1.0
  end
  
  return self
end

function Enemy:update(dt)
  -- Update slow effects
  for i = #self.slowEffects, 1, -1 do
    local slow = self.slowEffects[i]
    slow.duration = slow.duration - dt
    
    if slow.duration <= 0 then
      table.remove(self.slowEffects, i)
      self:updateSpeed()  -- Recalculate speed when a slow expires
    end
  end

  if not self.isMoving then return end  -- Skip movement logic if standing still
  
  -- Update damage number if it exists
  if self.damageNumber then
    self.damageNumber.age = self.damageNumber.age + dt
    
    -- Float upward
    self.damageNumber.z = Constants.CAMERA_HEIGHT - 10 + 
                         (self.damageNumber.floatSpeed * self.damageNumber.age)
    
    -- Remove old damage number
    if self.damageNumber.age >= self.damageNumber.lifetime then
      self.damageNumber = nil
    end
  end
  
  -- Get direction to player
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  
  -- Calculate angle to player
  self.targetAngle = math.atan2(dx, dy)
  
  -- Smoothly rotate towards target angle
  local angleDiff = (self.targetAngle - self.angle)
  -- Normalize angle difference to [-pi, pi]
  angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi
  
  self.angle = self.angle + math.sign(angleDiff) * 
               math.min(self.turnSpeed * dt, math.abs(angleDiff))
  
  -- Move forward (matching camera's coordinate system)
  self.x = self.x + math.sin(self.angle) * self.speed * dt
  self.y = self.y + math.cos(self.angle) * self.speed * dt
  
  -- Check for collision with player
  local distanceToPlayer = math.sqrt(dx * dx + dy * dy)
  
  if distanceToPlayer < self.damageRadius then
    if _G.player:takeDamage(self.damageAmount) then
      -- Optional: knock player back
      local knockbackForce = 100
      _G.player.x = _G.player.x + (dx / distanceToPlayer) * knockbackForce * dt
      _G.player.y = _G.player.y + (dy / distanceToPlayer) * knockbackForce * dt
    end
  end
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

-- Add hit method with damage numbers
function Enemy:hit(damage, isCritical)
  self.health = self.health - (damage or 25)
  
  -- Apply slow if player has frost rune
  if _G.player and _G.player.runeEffects.onHitSlow and _G.player.runeEffects.onHitSlow > 0 then
    local slowAmount = _G.player.runeEffects.onHitSlow
    local slowDuration = 2.0  -- 2 seconds slow duration
    
    print("Applying slow: " .. slowAmount)

    -- Add new slow effect
    table.insert(self.slowEffects, {
      amount = slowAmount,
      duration = slowDuration
    })
    
    -- Update speed with all active slows
    self:updateSpeed()
    
    -- Add frost visual effect when slowed
    if _G.effects then
      FrostOrb:spawnFrostEffect(self.x, self.y, 0.5)
    end
  end
  
  -- Create damage number
  self.damageNumber = DamageNumber:new({
    value = damage or 25,
    x = self.x,
    y = self.y,
    z = Constants.CAMERA_HEIGHT - 10,
    baseScale = isCritical and 1.5 or 1.0,
    isCritical = isCritical
  })
  
  -- Only queue death if not already dead
  if self.health <= 0 and not self.isDead then
    self.isDead = true
    
    -- Elite enemies drop orbs
    if self.isElite then
      -- Check if Elite Harvest power-up is active
      local orbDropChance = _G.player.hasEliteHarvest and 1.0 or 0.75  -- Increased from 0.25 to 0.75, 100% with power-up
      
      if math.random() < orbDropChance then
        local availableOrbs = _G.player.orbSpawner.orbTypes
        local randomOrbType = availableOrbs[math.random(#availableOrbs)]
        
        self.shouldDropOrb = {
          type = randomOrbType,
          x = self.x,
          y = self.y
        }
        print("Elite will drop orb: " .. randomOrbType)  -- Debug print
      end
    end
    
    -- Always drop experience
    self.shouldDropExp = true
    
    _G.mobSpawner:queueEnemyDeath(self)
  end
  
  return self.health <= 0
end

-- Add new function to update speed based on slows
function Enemy:updateSpeed()
  -- Start with base speed
  self.speed = self.baseSpeed
  
  -- Apply all active slows multiplicatively
  for _, slow in ipairs(self.slowEffects) do
    print("Applying slow: " .. slow.amount)
    self.speed = self.speed * (1 - slow.amount)
  end
  
  -- Ensure minimum speed
  self.speed = math.max(self.speed, self.baseSpeed * 0.2)  -- Can't go below 20% speed
end

return Enemy





























