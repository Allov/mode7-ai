local BaseOrb = require('src.orbs.baseorb')

local LightningOrb = BaseOrb:new({
    cooldown = 2.0, -- Attack every 2 seconds
    
    baseStats = {
        damage = 25,
        radius = 200,
        chainCount = 1 -- Number of targets to hit
    },
    
    -- Visual properties
    visualEffect = "lightning_arc",
    soundEffect = "thunder_crack"
})

function LightningOrb:onActivate()
    -- Find valid targets within radius
    local targets = self:findTargets()
    
    -- Calculate damage with rank scaling
    local damage = self:getScaledStat(self.baseStats.damage, 0.2) -- 20% increase per rank
    
    -- Number of targets increases with rank
    local targetCount = self.rank
    
    -- Attack random targets
    for i = 1, math.min(#targets, targetCount) do
        local target = targets[i]
        target:hit(damage)
        
        -- TODO: Spawn visual effects
        -- self:spawnLightningEffect(self.owner.x, self.owner.y, target.x, target.y)
    end
end

function LightningOrb:findTargets()
    local targets = {}
    local radius = self:getScaledStat(self.baseStats.radius, 0.1) -- 10% increase per rank
    
    -- TODO: Get enemies from game state and filter by distance
    -- for _, enemy in ipairs(enemies) do
    --     local distance = self:distanceTo(enemy)
    --     if distance <= radius then
    --         table.insert(targets, enemy)
    --     end
    -- end
    
    return targets
end

return LightningOrb
