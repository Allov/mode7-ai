local Lightning = {
    x = 0,
    y = 0,
    alpha = 1.0,
    lifetime = 0.3,  -- Increased slightly for better visibility
    age = 0
}

function Lightning:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Lightning:init(x, y)
    self.x = x
    self.y = y
    self.age = 0
    self.alpha = 1.0
    return self
end

function Lightning:update(dt)
    self.age = self.age + dt
    -- Slower fade out
    self.alpha = math.max(0, 1.0 - (self.age / self.lifetime))
    return self.age >= self.lifetime
end

return Lightning
