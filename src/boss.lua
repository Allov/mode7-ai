local Constants = require('src.constants')
local Enemy = require('src.enemy')
local Rune = require('src.rune')
local DamageNumber = require('src.damagenumber')

-- Create Boss by inheriting from Enemy
local Boss = Enemy:new({
  speed = 25,          -- Slower than normal enemies
  turnSpeed = 0.5,     -- Slower turning
  radius = 75,         -- Much bigger than normal enemies
  isMoving = true,
  health = 500,        -- Much more health
  maxHealth = 500,     -- Add maxHealth to match health
  damageAmount = 40,   -- Double damage
  damageRadius = 100,  -- Larger damage radius
  experienceValue = 500,  -- Increased from 100 to 500
  dropChance = 1.0,    -- 100% chance to drop exp (guaranteed)
  
  -- Boss specific properties
  enrageTimer = 0,
  enrageInterval = 10, -- Enrage every 10 seconds
  isEnraged = false,
  chargeSpeed = 400,   -- Fast charge speed
  chargeTargetX = 0,   -- Target position for charge
  chargeTargetY = 0,
  chargeDuration = 2,  -- How long the charge lasts
  chargeTimer = 0
})

function Boss:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  
  -- Ensure maxHealth is set properly
  o.maxHealth = o.health
  
  return o
end

function Boss:init(x, y)
  Enemy.init(self, x, y)  -- Call parent's init
  self.enrageTimer = 0
  self.isEnraged = false
  self.chargeTimer = 0
  self.isBoss = true     -- Add this line to properly flag as boss
  return self
end

function Boss:update(dt)
  -- Update enrage timer
  self.enrageTimer = self.enrageTimer + dt
  
  if self.enrageTimer >= self.enrageInterval and not self.isEnraged then
    -- Start enrage phase
    self.isEnraged = true
    self.chargeTimer = 0
    -- Target player's current position
    self.chargeTargetX = _G.player.x
    self.chargeTargetY = _G.player.y
    -- Calculate angle to target
    local dx = self.chargeTargetX - self.x
    local dy = self.chargeTargetY - self.y
    self.angle = math.atan2(dy, dx)
  end
  
  if self.isEnraged then
    -- Update charge
    self.chargeTimer = self.chargeTimer + dt
    
    -- Move towards charge target
    self.x = self.x + math.cos(self.angle) * self.chargeSpeed * dt
    self.y = self.y + math.sin(self.angle) * self.chargeSpeed * dt
    
    -- End charge after duration
    if self.chargeTimer >= self.chargeDuration then
      self.isEnraged = false
      self.enrageTimer = 0
    end
  else
    -- Normal movement
    local dx = _G.player.x - self.x
    local dy = _G.player.y - self.y
    local targetAngle = math.atan2(dy, dx)
    
    -- Smoothly rotate towards player
    local angleDiff = (targetAngle - self.angle)
    angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi
    self.angle = self.angle + math.sign(angleDiff) * self.turnSpeed * dt
    
    -- Move forward
    self.x = self.x + math.cos(self.angle) * self.speed * dt
    self.y = self.y + math.sin(self.angle) * self.speed * dt
  end
  
 
  -- Check for collision with player
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  local distanceToPlayer = math.sqrt(dx * dx + dy * dy)
  
  if distanceToPlayer < self.damageRadius then
    if _G.player:takeDamage(self.damageAmount) then
      -- Stronger knockback than normal enemies
      local knockbackForce = 200
      _G.player.x = _G.player.x + (dx / distanceToPlayer) * knockbackForce * dt
      _G.player.y = _G.player.y + (dy / distanceToPlayer) * knockbackForce * dt
    end
  end
end

function Boss:hit(damage, isCritical)
  self.health = self.health - (damage or 25)
  
  -- Create damage number
  self.damageNumber = DamageNumber:new({
    value = damage or 25,
    x = self.x,
    y = self.y,
    z = Constants.CAMERA_HEIGHT - 10,
    baseScale = isCritical and 1.5 or 1.0,
    isCritical = isCritical
  })
  
  -- Check for death
  if self.health <= 0 and not self.isDead then
    self.isDead = true
    
    -- Always drop experience
    self.shouldDropExp = true
    
    -- Bosses always drop a random rune
    local runeTypes = {}
    for runeType, _ in pairs(Rune.TYPES) do
      table.insert(runeTypes, runeType)
    end
    
    self.shouldDropRune = {
      type = runeTypes[math.random(#runeTypes)],
      x = self.x,
      y = self.y
    }
    
    -- Queue death for processing
    _G.mobSpawner:queueEnemyDeath(self)
  end
  
  return self.health <= 0
end

return Boss








