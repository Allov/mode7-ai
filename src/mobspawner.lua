local Enemy = require('src.enemy')
local Boss = require('src.boss')
local ExperienceOrb = require('src.experienceorb')

local MobSpawner = {
    -- Spawn control variables
    spawnTimer = 0,
    minSpawnInterval = 2.0,
    spawnIntervalDecay = 0.99,
    spawnDistance = 800,
    minEnemyDistance = 500,
    spawnInterval = 12.0,
    
    -- Wave control
    enemiesPerWave = 1,
    maxEnemiesPerWave = 8,
    waveCount = 0,
    enemiesPerWaveIncrease = 0.2,  -- Increase by 0.2 enemies per wave (rounded up)
    
    -- References to game state
    enemies = nil,
    player = nil,
    experienceOrbs = nil,
    recentDeaths = {}  -- Queue for recently dead enemies
}

function MobSpawner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MobSpawner:init(enemies, player, experienceOrbs)
    self.enemies = enemies
    self.player = player
    self.experienceOrbs = experienceOrbs
    self.spawnTimer = 0
    self.spawnInterval = 12.0
    self.recentDeaths = {}
    self.enemiesPerWave = 1
    self.waveCount = 0
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

-- Add enemy to death queue
function MobSpawner:queueEnemyDeath(enemy)
    table.insert(self.recentDeaths, enemy)
end

-- Process death queue
function MobSpawner:processDeathQueue()
    for i = #self.recentDeaths, 1, -1 do
        local deadEnemy = self.recentDeaths[i]
        
        -- Find and remove enemy from main list
        for j = #self.enemies, 1, -1 do
            if self.enemies[j] == deadEnemy then
                -- Handle experience drops
                if deadEnemy.shouldDropExp then
                    local expValue = deadEnemy.isElite and (deadEnemy.experienceValue * 2) or deadEnemy.experienceValue
                    local expOrb = ExperienceOrb:new():init(deadEnemy.x, deadEnemy.y, expValue)
                    table.insert(self.experienceOrbs, expOrb)
                end
                
                -- Handle orb drops from elites
                if deadEnemy.shouldDropOrb then
                    _G.orbItemSpawner:spawnOrbItem(
                        deadEnemy.shouldDropOrb.type,
                        deadEnemy.shouldDropOrb.x,
                        deadEnemy.shouldDropOrb.y
                    )
                end
                
                table.remove(self.enemies, j)
                break
            end
        end
        
        -- Remove from death queue
        table.remove(self.recentDeaths, i)
    end
end

function MobSpawner:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        self.waveCount = self.waveCount + 1
        
        -- Calculate how many enemies to spawn this wave
        local spawnCount = math.ceil(self.enemiesPerWave)
        
        -- Spawn multiple enemies
        for i = 1, spawnCount do
            self:spawnEnemy()
        end
        
        -- Increase enemies per wave, but don't exceed maximum
        self.enemiesPerWave = math.min(
            self.maxEnemiesPerWave,
            self.enemiesPerWave + self.enemiesPerWaveIncrease
        )
        
        -- Reduce spawn interval, but not below minimum
        self.spawnInterval = math.max(
            self.minSpawnInterval,
            self.spawnInterval * self.spawnIntervalDecay
        )
    end
    
    -- Process any queued deaths
    self:processDeathQueue()
end

return MobSpawner

