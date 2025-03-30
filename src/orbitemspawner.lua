local OrbItem = require('src.orbitem')
local GameData = require('src.gamedata')

local OrbItemSpawner = {
    -- Spawn settings
    maxOrbItems = 5,
    spawnInterval = 60.0, -- Spawn orb every 60 seconds
    spawnTimer = 0,
    spawnDistance = 600,
    minSpawnDistance = 150,
    
    -- References
    player = nil,
    orbItems = {},
}

function OrbItemSpawner:safePrint(message)
    if _G.console then
        _G.console:print(message)
    else
        print(message)
    end
end

function OrbItemSpawner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OrbItemSpawner:init(player)
    self.player = player
    self.orbItems = {}
    -- Ensure global reference exists for OrbItem pickup logic
    _G.orbItems = self.orbItems
    return self
end

function OrbItemSpawner:findValidSpawnPosition()
    -- Try up to 10 different positions
    for _ = 1, 10 do
        local angle = math.random() * math.pi * 2
        local distance = self.minSpawnDistance + math.random() * (self.spawnDistance - self.minSpawnDistance)
        
        local x = self.player.x + math.cos(angle) * distance
        local y = self.player.y + math.sin(angle) * distance
        
        -- TODO: Add collision checking here if needed
        return x, y
    end
    
    return nil, nil
end

function OrbItemSpawner:getRandomOrbType()
    local availableTypes = self.player.orbSpawner.orbTypes
    return availableTypes[math.random(#availableTypes)]
end

function OrbItemSpawner:spawnOrbItem(orbType, x, y)
    if #self.orbItems >= self.maxOrbItems then
        return nil
    end
    
    if not x or not y then
        x, y = self:findValidSpawnPosition()
    end
    
    if x and y then
        orbType = orbType or self:getRandomOrbType()
        
        local orbItem = OrbItem:new():init(x, y, orbType, self.player)  -- Pass player reference
        table.insert(self.orbItems, orbItem)
        
        return orbItem
    end
    
    return nil
end

function OrbItemSpawner:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        local newOrb = self:spawnOrbItem()
        if newOrb then
            self:safePrint("Spawned new " .. newOrb.type .. " orb")
        end
    end
    
    -- Update and cleanup collected orb items
    for i = #self.orbItems, 1, -1 do
        local orbItem = self.orbItems[i]
        if not orbItem then
            self:safePrint("Warning: nil orb item at index " .. i)
        else
            if orbItem:update(dt) then
                table.remove(self.orbItems, i)
            end
        end
    end
end

function OrbItemSpawner:getOrbItems()
    return self.orbItems
end

return OrbItemSpawner



