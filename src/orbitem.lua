local GameData = require('src.gamedata')

local OrbItem = {
    x = 0,
    y = 0,
    type = nil,
    pickupRange = 50,
    age = 0,
    lifetime = 30,
    color = nil,
    player = nil  -- Add player reference
}

function OrbItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OrbItem:init(x, y, orbType, player)  -- Add player parameter
    self.x = x
    self.y = y
    self.type = orbType
    self.age = 0
    self.player = player
    
    -- Set color from GameData
    if GameData.ORBS[orbType] then
        self.color = GameData.ORBS[orbType].color
    else
        self.color = {1, 1, 1}  -- Default to white if type not found
    end
    
    return self
end

function OrbItem:update(dt)
    self.age = self.age + dt
    
    -- Check if expired
    if self.age >= self.lifetime then
        return true
    end
    
    -- Calculate distance to player
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check for pickup
    if distance < self.pickupRange then
        local success = self.player.orbSpawner:addOrb(self.type)
        if success then
            print("Picked up " .. self.type .. " orb")  -- Only log successful pickups
            return true
        end
    end
    
    return false
end

return OrbItem
