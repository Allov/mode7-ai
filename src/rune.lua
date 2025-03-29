local GameData = require('src.gamedata')

local Rune = {
  x = 0,
  y = 0,
  z = 100,  -- Increased from 40 to 100 to float higher above ground
  radius = 25,
  pickupRadius = 75,
  type = "none",
  rotationSpeed = 1,
  angle = 0,
  glowPhase = 0,
}

-- Define rune types and their effects
Rune.TYPES = {
  WISDOM = {
    name = "Rune of Wisdom",
    color = {0.4, 0.8, 1}, -- Light blue
    effects = {
      experienceMultiplier = 1.25,    -- 25% more XP
      powerDurationMultiplier = 1.50,  -- 50% longer power-ups
      moveSpeedMultiplier = 1.05      -- 5% more speed
    },
    description = "XP +25%, Power Duration +50%, Speed +5%",
    rarity = 2
  },
  POWER = {
    name = "Rune of Power",
    color = {1, 0.3, 0.3}, -- Red
    effects = {
      damageMultiplier = 1.10,        -- 10% more damage
      critChanceBonus = 0.02,         -- 2% more crit chance
      powerDurationMultiplier = 1.25,  -- 25% longer power-ups
      fireRateMultiplier = 1.10       -- 10% faster firing
    },
    description = "Damage +10%, Crit +2%, Power Duration +25%, Fire Rate +10%",
    rarity = 2
  },
  SWIFTNESS = {
    name = "Rune of Swiftness",
    color = {1, 0.7, 0}, -- Golden orange
    effects = {
      fireRateMultiplier = 1.15,     -- 15% faster firing
      moveSpeedMultiplier = 1.10,    -- 10% more speed
      powerDurationMultiplier = 1.15  -- 15% longer power-ups
    },
    description = "Fire Rate +15%, Speed +10%, Power Duration +15%",
    rarity = 2
  },
  MULTISHOT = {
    name = "Rune of Multishot",
    color = {0.7, 0.3, 1.0}, -- Purple
    effects = {
      projectileCount = 1,        -- Adds 1 additional projectile
      fireRateMultiplier = 0.85,  -- 15% slower fire rate to balance
      damageMultiplier = 0.9      -- 10% less damage per projectile
    },
    description = "Extra Projectile, Fire Rate -15%, Damage -10%",
    rarity = 3  -- Slightly rarer than other runes
  }
}

function Rune:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Rune:init(x, y, type)
  self.x = x
  self.y = y
  self.type = type
  self.angle = 0
  self.glowPhase = 0
  -- Add z initialization
  self.z = 100  -- Match the default z value
  return self
end

function Rune:distanceTo(x, y)
  local dx = self.x - x
  local dy = self.y - y
  return math.sqrt(dx * dx + dy * dy)
end

function Rune:update(dt)
  -- Rotate the rune
  self.angle = self.angle + self.rotationSpeed * dt
  
  -- Glow effect
  self.glowPhase = (self.glowPhase + dt) % (2 * math.pi)
  
  -- Check for player pickup
  local dx = _G.player.x - self.x
  local dy = _G.player.y - self.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  if distance < self.pickupRadius then
    _G.player:addRune(self.type)
    return true -- Remove rune
  end
  
  return false
end

return Rune





