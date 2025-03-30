local BaseOrb = require('src.orbs.baseorb')
local Projectile = require('src.projectile')

local PulseOrb = BaseOrb:new({
    type = "pulse",
    cooldown = 2.0,
    
    baseStats = {
        damage = 15,
        projectileCount = 4,
        projectileSpeed = 200,
        range = 300
    },
    
    color = {1.0, 1.0, 0.8}
})

function PulseOrb:onActivate()
    -- Calculate number of projectiles (4 + rank)
    local projectileCount = self.baseStats.projectileCount + self.rank
    
    -- Calculate damage with rank scaling (20% increase per rank)
    local damage = self:getScaledStat(self.baseStats.damage, 0.2)
    
    -- Create projectiles in a ring pattern
    for i = 1, projectileCount do
        -- Calculate angle for even distribution
        local angle = (i - 1) * (2 * math.pi / projectileCount)
        
        -- Create proper Projectile instance and initialize it
        local projectile = Projectile:new():init(
            self.owner.x,  -- x position
            self.owner.y,  -- y position
            angle,         -- firing angle
            self.owner.z   -- height (use owner's height)
        )
        
        -- Override projectile properties
        projectile.baseDamage = damage
        projectile.baseSpeed = self.baseStats.projectileSpeed
        projectile.speed = self.baseStats.projectileSpeed
        projectile.color = self.color
        
        -- Add to global projectiles table
        table.insert(_G.projectiles, projectile)
    end
end

function PulseOrb:onRankUp()
    -- Increase projectile count and damage on rank up
    print(string.format("Pulse Orb ranked up to %d", self.rank))
end

return PulseOrb

