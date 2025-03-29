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
  }
}

return GameData