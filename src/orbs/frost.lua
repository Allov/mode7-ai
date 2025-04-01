local BaseOrb = require('src.orbs.baseorb')

local FrostOrb = BaseOrb:new({
    type = "frost",
    cooldown = 3.0,
    
    baseStats = {
        damage = 5,           -- Initial hit damage
        dotDamage = 3,        -- Damage over time
        radius = 250,
        slowAmount = 0.5,     -- 50% slow
        duration = 4.0,       -- Effect duration
        tickRate = 1.0        -- DoT tick rate
    },
    
    color = {0.5, 0.8, 1.0},  -- Ice blue
    
    -- Track affected targets
    frozenTargets = {}
})

function FrostOrb:init(owner)
    BaseOrb.init(self, owner)
    self.frozenTargets = {}
    return self
end

function FrostOrb:update(dt)
    BaseOrb.update(self, dt)
    
    -- Update frozen targets
    for i = #self.frozenTargets, 1, -1 do
        local data = self.frozenTargets[i]
        data.duration = data.duration - dt
        data.tickTimer = data.tickTimer - dt
        
        -- Apply periodic damage
        if data.tickTimer <= 0 then
            if data.target.hit then  -- Check if target still exists
                data.target:hit(self:getScaledStat(self.baseStats.dotDamage, 0.15))
                data.tickTimer = self.baseStats.tickRate
                
                -- Spawn frost particle effect on damage tick
                if _G.effects then
                    self:spawnFrostEffect(data.target.x, data.target.y, 0.5)
                end
            end
        end
        
        -- Remove expired effects
        if data.duration <= 0 then
            -- Remove slow effect
            if data.target.speed then
                data.target.speed = data.target.speed / (1 - self:getScaledStat(self.baseStats.slowAmount, 0.05))
            end
            table.remove(self.frozenTargets, i)
        end
    end
end

function FrostOrb:spawnFrostEffect(x, y, duration)
    -- Initialize effects table if it doesn't exist
    _G.effects = _G.effects or {}
    
    -- Create frost nova effect
    local frostEffect = {
        type = "frost",
        object = {
            x = x,
            y = y,
            angle = 0,  -- Add initial angle
            rotation = math.random() * math.pi * 2,
            scale = 1.0,
            alpha = 0.8,
            duration = duration or 1.0,
            update = function(self, dt)
                self.rotation = self.rotation + dt * 1.5  -- Rotate effect
                self.alpha = self.alpha - dt / self.duration
                self.scale = self.scale + dt * 2.0  -- Grow effect faster
                return self.alpha <= 0  -- Remove when fully faded
            end
        }
    }

    table.insert(_G.effects, frostEffect)

    local frostNovaEffect = {
        type = "frost_nova",
        object = {
            x = x,
            y = y,
            angle = 0,  -- Add initial angle
            rotation = math.random() * math.pi * 2,
            scale = 1.0,
            alpha = 0.8,
            duration = duration or 1.0,
            update = function(self, dt)
                self.rotation = self.rotation + dt * 1.5  -- Rotate effect
                self.alpha = self.alpha - dt / self.duration
                self.scale = self.scale + dt * 2.0  -- Grow effect faster
                return self.alpha <= 0  -- Remove when fully faded
            end
        }
    }

    -- table.insert(_G.effects, frostNovaEffect) -- disable for now
    
end

function FrostOrb:onActivate()
    -- Calculate stats with rank scaling
    local damage = self:getScaledStat(self.baseStats.damage, 0.2)
    local radius = self:getScaledStat(self.baseStats.radius, 0.1)
    local slowAmount = self:getScaledStat(self.baseStats.slowAmount, 0.05)
    
    -- Find targets in radius
    local targets = self:findTargetsInRadius(radius)
    if #targets == 0 then return end
    
    -- Apply frost effect to targets
    for _, target in ipairs(targets) do
        -- Initial damage
        target:hit(damage)
        
        -- Apply slow effect
        if target.speed then
            target.speed = target.speed * (1 - slowAmount)
        end
        
        -- Add to frozen targets
        table.insert(self.frozenTargets, {
            target = target,
            duration = self.baseStats.duration,
            tickTimer = self.baseStats.tickRate
        })
        
        -- Spawn frost effect at target
        if _G.effects then
            self:spawnFrostEffect(target.x, target.y, 1.0)
        end
    end
    
    -- Spawn area effect at activation
    if _G.effects then
        local centerEffect = {
            type = "frost_nova",
            object = {
                x = self.owner.x,
                y = self.owner.y,
                angle = 0,
                rotation = 0,  -- Fixed at 0, no rotation
                scale = 0.2,   -- Start a bit bigger
                alpha = 0.8,
                duration = 0.5, -- Shorter duration for snappier effect
                update = function(self, dt)
                    self.scale = self.scale + dt * 3.0  -- Faster expansion
                    self.alpha = self.alpha - dt / self.duration
                    return self.alpha <= 0
                end
            }
        }
        table.insert(_G.effects, centerEffect)
    end
end

return FrostOrb




