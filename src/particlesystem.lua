local ParticleSystem = {
    particles = {},
    x = 0,
    y = 0,
    color = {1, 1, 1},
    lifetime = 1.0,
    particleCount = 10,
    spread = 10
}

function ParticleSystem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    -- Initialize particles based on settings
    o.particles = {}
    for i = 1, o.particleCount do
        -- Random angle within spread
        local angle = math.random() * math.pi * 2
        local speed = math.random() * 50 + 50
        
        table.insert(o.particles, {
            x = o.x,
            y = o.y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            life = o.lifetime,
            alpha = 1.0
        })
    end
    
    return o
end

function ParticleSystem:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        
        -- Update position
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        
        -- Update lifetime
        p.life = p.life - dt
        p.alpha = p.life / self.lifetime
        
        -- Remove dead particles
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    return #self.particles == 0
end

function ParticleSystem:draw()
    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, 2)
    end
    
    love.graphics.pop()
end

return ParticleSystem