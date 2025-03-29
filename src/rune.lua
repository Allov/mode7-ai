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
    rarity = 2  -- Add rarity field
  },
  POWER = {
    name = "Rune of Power",
    color = {1, 0.3, 0.3}, -- Red
    effects = {
      damageMultiplier = 1.10,        -- 10% more damage
      critChanceBonus = 0.02,         -- 2% more crit chance
      powerDurationMultiplier = 1.25   -- 25% longer power-ups
    },
    description = "Damage +10%, Crit +2%, Power Duration +25%",
    rarity = 2  -- Add rarity field
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



