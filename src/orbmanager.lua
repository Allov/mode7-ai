local OrbManager = {
    orbs = {},
    maxOrbs = 10,
    orbRadius = 30,
    rotationSpeed = 2,
    owner = nil,
    currentRotation = 0
}

function OrbManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.orbs = {}
    o.currentRotation = 0
    return o
end

function OrbManager:init(owner)
    self.owner = owner
    self.orbs = {}
    return self
end

function OrbManager:update(dt)
    -- Update orb positions
    local numOrbs = #self.orbs
    if numOrbs > 0 and self.owner then
        -- Update rotation
        self.currentRotation = self.currentRotation + self.rotationSpeed * dt
        
        -- Calculate orbit positions and update orbs
        for i, orb in ipairs(self.orbs) do
            -- Calculate position in orbit
            local angle = self.currentRotation + ((i-1) / numOrbs) * (2 * math.pi)
            orb.x = self.owner.x + math.cos(angle) * self.orbRadius
            orb.y = self.owner.y + math.sin(angle) * self.orbRadius
            
            -- Update orb logic
            orb:update(dt)
            
            -- Activate orb if cooldown is ready
            if orb:canActivate() then
                orb:activate()
            end
        end
    end
end

function OrbManager:addOrb(orbType)
    if #self.orbs >= self.maxOrbs then
        return false
    end
    
    -- Ensure we have an owner
    if not self.owner then
        return false
    end
    
    -- Check if we already have this orb type
    for _, orb in ipairs(self.orbs) do
        if orb.type == orbType then
            return orb:increaseRank()
        end
    end
    
    -- Create new orb with initial position
    local newOrb = require('src.orbs.' .. orbType):new()
    newOrb:init(self.owner)
    newOrb.x = self.owner.x
    newOrb.y = self.owner.y
    table.insert(self.orbs, newOrb)
    return true
end

function OrbManager:removeOrb(orbType)
    for i, orb in ipairs(self.orbs) do
        if orb.type == orbType then
            table.remove(self.orbs, i)
            return true
        end
    end
    return false
end

function OrbManager:draw()
    if not self.owner then return end
    
    for i, orb in ipairs(self.orbs) do
        -- Draw orb visual
        love.graphics.setColor(0, 1, 1, 1) -- Cyan color
        love.graphics.circle('fill', orb.x, orb.y, 8)
        
        -- Draw rank indicator
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(orb.rank, orb.x - 4, orb.y - 6)
    end
end

return OrbManager



