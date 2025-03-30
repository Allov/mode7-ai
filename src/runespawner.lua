local Rune = require('src.rune')

local RuneSpawner = {
    -- Spawn settings
    maxRunes = 8,
    spawnInterval = 120.0, -- Spawn rune every 120 seconds
    spawnTimer = 0,
    spawnDistance = 800,
    minSpawnDistance = 200,
    
    -- References
    player = nil,
    runes = {},
}

-- Add safe print function
function RuneSpawner:safePrint(message)
    if _G.console then
        _G.console:print(message)
    else
        print(message) -- Fallback to regular print
    end
end

function RuneSpawner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RuneSpawner:init(player)
    self.player = player
    self.runes = {}
    return self
end

function RuneSpawner:findValidSpawnPosition()
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

function RuneSpawner:getRandomRuneType()
    local availableTypes = {}
    for runeType, _ in pairs(Rune.TYPES) do
        table.insert(availableTypes, runeType)
    end
    return availableTypes[math.random(#availableTypes)]
end

function RuneSpawner:spawnRune(runeType, x, y)
    if #self.runes >= self.maxRunes then
        self:safePrint("Cannot spawn rune: maximum runes reached (" .. self.maxRunes .. ")")
        return nil
    end
    
    if not x or not y then
        x, y = self:findValidSpawnPosition()
    end
    
    if x and y then
        runeType = runeType or self:getRandomRuneType()
        
        local rune = Rune:new():init(x, y, runeType)
        table.insert(self.runes, rune)
        
        -- Update global references
        _G.runes = self.runes
        if _G.console then
            _G.console.runes = self.runes
        end
        
        local message = string.format("Spawned %s rune at X:%.1f Y:%.1f (Total: %d)", 
            Rune.TYPES[runeType].name, x, y, #self.runes)
        self:safePrint(message)
        
        if _G.showNotification then
            _G.showNotification("New Rune Spawned: " .. Rune.TYPES[runeType].name)
        end
        
        return rune
    end
    
    self:safePrint("Failed to find valid spawn position for rune")
    return nil
end

function RuneSpawner:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        self:spawnRune()
    end
    
    -- Update and cleanup collected runes
    for i = #self.runes, 1, -1 do
        local rune = self.runes[i]
        if rune:update(dt) then
            table.remove(self.runes, i)
            self:safePrint("Rune collected!")
        end
    end
    
    -- Ensure global runes table is updated
    _G.runes = self.runes
end

function RuneSpawner:getRunes()
    return self.runes
end

return RuneSpawner









