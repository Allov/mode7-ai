local GameData = {
  POWERUP_TYPES = {
    -- Common (Rarity 1)
    RANGE = {
      name = "range",
      color = {0, 1, 1},  -- Cyan
      multiplier = 1.3,   -- 30% increase
      description = "Pickup Range +",
      rarity = 1
    },
    SPEED = {
      name = "speed",
      color = {1, 1, 0},  -- Yellow
      multiplier = 1.2,   -- 20% increase
      description = "Speed +",
      rarity = 1
    },
    -- Uncommon (Rarity 2)
    DAMAGE = {
      name = "damage",
      color = {1, 0, 0},  -- Red
      multiplier = 1.5,   -- 50% increase
      description = "Damage +",
      rarity = 2
    },
    -- Rare (Rarity 3)
    HEALTH = {
      name = "health",
      color = {0, 1, 0},  -- Green
      multiplier = 1.5,   -- 50% increase
      description = "Max Health +",
      rarity = 3
    }
  },

  -- Add RUNE_TYPES
  RUNE_TYPES = {
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
        powerDurationMultiplier = 1.25   -- 25% longer power-ups
      },
      description = "Damage +10%, Crit +2%, Power Duration +25%",
      rarity = 2
    }
  }
}

return GameData
