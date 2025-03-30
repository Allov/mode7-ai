local BaseOrb = require('src.orbs.baseorb')

local FireOrb = BaseOrb:new({
    type = "fire",
    cooldown = 1.5,
    
    baseStats = {
        damage = 8,
        radius = 200,
        duration = 0.5,  -- How long the fire effect lasts
        tickRate = 0.1   -- How often damage is applied
    },
    
    color = {1.0, 0.4, 0.0},  -- Orange
    
    -- Track active fire effects
    activeEffects = {}
})

function FireOrb:onActivate()
    -- Calculate damage with rank scaling (15% increase per rank)
    local damage = self:getScaledStat(self.baseStats.damage, 0.15)
    local radius = self:getScaledStat(self.baseStats.radius, 0.1)  -- 10% increase per rank
    
    -- Find targets first
    local targets = self:findTargetsInRadius(radius)
    if #targets == 0 then return end
    
    -- Pick a random target for the fire effect
    local target = targets[math.random(#targets)]
    
    -- Create new fire effect at target position
    local effect = {
        x = target.x,
        y = target.y,
        radius = radius,
        damage = damage,
        duration = self.baseStats.duration,
        tickTimer = 0,
        totalTime = 0,
        rotation = math.random() * math.pi * 2  -- Random initial rotation
    }
    
    table.insert(self.activeEffects, effect)
    
    -- Add visual effect at target position
    if _G.effects then
        local fireEffect = {
            type = "fire",
            object = {
                x = target.x,
                y = target.y,
                rotation = effect.rotation,
                scale = radius / 32,  -- Scale based on radius
                alpha = 0.8,
                update = function(self, dt)
                    self.rotation = self.rotation + dt * 2  -- Rotate effect
                    self.alpha = self.alpha - dt / effect.duration
                    return self.alpha <= 0
                end
            }
        }
        table.insert(_G.effects, fireEffect)
    end
end

function FireOrb:update(dt)
    BaseOrb.update(self, dt)
    
    -- Update active fire effects
    for i = #self.activeEffects, 1, -1 do
        local effect = self.activeEffects[i]
        
        -- Update timers
        effect.totalTime = effect.totalTime + dt
        effect.tickTimer = effect.tickTimer + dt
        
        -- Check if it's time to apply damage
        if effect.tickTimer >= self.baseStats.tickRate then
            effect.tickTimer = 0
            
            -- Find enemies in range and apply damage
            local targets = self:findTargetsInRadius(effect.radius, effect.x, effect.y)
            for _, target in ipairs(targets) do
                target:hit(effect.damage)
            end
        end
        
        -- Remove effect if duration is up
        if effect.totalTime >= effect.duration then
            table.remove(self.activeEffects, i)
        end
    end
end

return FireOrb


