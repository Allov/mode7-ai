local BaseOrb = require('src.orbs.baseorb')
local Lightning = require('src.effects.lightning')

local LightningOrb = BaseOrb:new({
    type = "lightning",
    cooldown = 2.0,
    
    baseStats = {
        damage = 25,
        radius = 500,
        chainCount = 1
    },
    
    color = {0.3, 0.3, 1.0}
})

function LightningOrb:onActivate()
    local targets = self:findTargetsInRadius(self:getScaledStat(self.baseStats.radius, 0.1))
    
    if #targets == 0 then return end
    
    local damage = self:getScaledStat(self.baseStats.damage, 0.2)
    local targetCount = self.rank
    
    print("Lightning orb activated, targets found:", #targets)  -- Debug print
    
    -- Initialize _G.effects if it doesn't exist
    _G.effects = _G.effects or {}
    
    for i = 1, math.min(#targets, targetCount) do
        local target = targets[i]
        target:hit(damage)
        
        -- Create lightning effect
        local lightning = Lightning:new()
        lightning:init(target.x, target.y)
        
        -- Add to global effects table
        table.insert(_G.effects, {
            type = "lightning",
            object = lightning
        })
    end
end

return LightningOrb

