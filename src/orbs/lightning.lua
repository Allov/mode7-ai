local BaseOrb = require('src.orbs.baseorb')

local LightningOrb = BaseOrb:new({
    type = "lightning",
    cooldown = 2.0, -- Attack every 2 seconds per docs
    
    baseStats = {
        damage = 25,
        radius = 200,
        chainCount = 1 -- Number of targets to hit
    },
    
    -- Visual properties
    visualEffect = "lightning_arc",
    soundEffect = "thunder_crack",
    color = {0.3, 0.3, 1.0} -- Light blue for lightning
})

function LightningOrb:onActivate()
    -- Find valid targets within radius
    local targets = self:findTargetsInRadius(self:getScaledStat(self.baseStats.radius, 0.1)) -- 10% increase per rank
    
    if #targets == 0 then return end -- No targets found
    
    -- Calculate damage with rank scaling
    local damage = self:getScaledStat(self.baseStats.damage, 0.2) -- 20% increase per rank
    
    -- Number of targets to hit equals current rank
    local targetCount = self.rank
    
    -- Attack random targets
    local i = 1
    while i <= math.min(#targets, targetCount) do
        local target = targets[i]
        local isDead = target:hit(damage)
        
        -- If enemy died, remove it from targets list
        if isDead then
            table.remove(targets, i)
            -- Don't increment i since we removed the current target
        else
            i = i + 1
        end
        
        -- TODO: Add visual effects when implemented
        -- self:spawnEffect("lightning_arc", self.x, self.y, target.x, target.y)
        -- self:playSound("thunder_crack")
    end
end

return LightningOrb

