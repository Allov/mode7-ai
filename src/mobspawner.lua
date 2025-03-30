local Enemy = require('src.enemy')
local Boss = require('src.boss')

local MobSpawner = {
    -- Spawn control variables
    spawnTimer = 0,
    minSpawnInterval = 2.0,
    spawnIntervalDecay = 0.99,
    spawnDistance = 800,
    minEnemyDistance = 200,
    spawnInterval = 12.0,
    
    -- References to game state
    enemies = nil,
    player = nil
}

function MobSpawner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MobSpawner:init(enemies, player)
    self.enemies = enemies
    self.player = player
    self.spawnTimer = 0
    self.spawnInterval = 12.0
    return self
end

function MobSpawner:findValidSpawnPosition()
    -- Try up to 10 different positions
    for _ = 1, 10 do
        -- Generate random angle around player
        local angle = math.random() * math.pi * 2
        
        -- Calculate spawn position
        local spawnX = self.player.x + math.cos(angle) * self.spawnDistance
        local spawnY = self.player.y + math.sin(angle) * self.spawnDistance
        
        -- Check distance to nearest enemy
        if self:getDistanceToNearestEnemy(spawnX, spawnY) >= self.minEnemyDistance then
            return spawnX, spawnY
        end
    end
    
    return nil, nil
end

function MobSpawner:getDistanceToNearestEnemy(x, y)
    local minDistance = math.huge
    for _, enemy in ipairs(self.enemies) do
        local dx = x - enemy.x
        local dy = y - enemy.y
        local distance = math.sqrt(dx * dx + dy * dy)
        minDistance = math.min(minDistance, distance)
    end
    return minDistance
end

function MobSpawner:spawnEnemy()
    -- Find valid spawn position
    local spawnX, spawnY = self:findValidSpawnPosition()
    
    -- Only spawn if valid position found
    if spawnX and spawnY then
        -- 10% chance to spawn an elite enemy
        local isElite = math.random() < 0.10
        
        -- Create and add new enemy
        local enemy = Enemy:new():init(spawnX, spawnY, isElite)
        table.insert(self.enemies, enemy)
        
        -- Reduce spawn interval, but not below minimum
        self.spawnInterval = math.max(self.minSpawnInterval, 
                                    self.spawnInterval * self.spawnIntervalDecay)
        
        return enemy
    end
    return nil
end

function MobSpawner:spawnBoss()
    -- Find valid spawn position (similar to enemy spawn)
    local angle = math.random() * math.pi * 2
    local bossSpawnDistance = 1200  -- Increased from regular spawn distance
    
    local spawnX = self.player.x + math.cos(angle) * bossSpawnDistance
    local spawnY = self.player.y + math.sin(angle) * bossSpawnDistance
    
    -- Create and add new boss
    local boss = Boss:new():init(spawnX, spawnY)
    table.insert(self.enemies, boss)
    
    return boss
end

function MobSpawner:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        self:spawnEnemy()
    end
end

return MobSpawner