local BaseOrb = {
    rank = 1,
    maxRank = 10,
    cooldown = 0,
    currentCooldown = 0,
    owner = nil,
    active = true,
    
    -- Visual properties
    visualEffect = nil,
    soundEffect = nil,
    
    -- Base stats that all orbs share
    baseStats = {
        damage = 0,
        radius = 0,
        duration = 0
    },
    
    -- Add these properties
    type = "base",
    color = {0, 1, 1}, -- Default cyan
    particles = {},
    
    -- Add targeting methods
    findTargetsInRadius = function(self, radius)
        local targets = {}
        -- Get enemies from global enemies table
        local enemies = _G.enemies or {}
        
        for _, enemy in ipairs(enemies) do
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= radius then
                table.insert(targets, enemy)
            end
        end
        
        -- Shuffle targets for random selection
        for i = #targets, 2, -1 do
            local j = math.random(i)
            targets[i], targets[j] = targets[j], targets[i]
        end
        
        return targets
    end,
    
    -- Add effect system
    spawnEffect = function(self, effectType, x, y, target)
        -- TODO: Implement effect system
        -- Example: lightning arc, fire trail, etc.
    end,
    
    -- Add sound system
    playSound = function(self, soundName)
        -- TODO: Implement sound system
    end
}

function BaseOrb:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BaseOrb:init(owner)
    self.owner = owner
    self.currentCooldown = 0
    return self
end

function BaseOrb:update(dt)
    if self.currentCooldown > 0 then
        self.currentCooldown = self.currentCooldown - dt
    end
end

function BaseOrb:canActivate()
    return self.currentCooldown <= 0
end

function BaseOrb:activate()
    if self:canActivate() then
        self.currentCooldown = self.cooldown
        self:onActivate()
    end
end

function BaseOrb:onActivate()
    -- Override in derived classes
end

function BaseOrb:increaseRank()
    if self.rank < self.maxRank then
        self.rank = self.rank + 1
        self:onRankUp()
        return true
    end
    return false
end

function BaseOrb:onRankUp()
    -- Override in derived classes
end

function BaseOrb:getScaledStat(baseStat, scaling)
    return baseStat + (baseStat * scaling * self.rank)
end

return BaseOrb

