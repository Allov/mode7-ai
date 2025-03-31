local Enemy = require('src.enemy')
local Constants = require('src.constants')

local General = Enemy:new({
    -- Base stats (higher than normal enemies but lower than bosses)
    health = 500,
    maxHealth = 500,
    speed = 35,
    turnSpeed = 0.75,
    radius = 30,
    damageAmount = 30,
    damageRadius = 75,
    experienceValue = 200,
    dropChance = 1.0,  -- Always drops exp
    
    -- General specific properties
    isGeneral = true,
    buffRadius = 150 * Constants.SCALE,  -- Increased radius for better visibility
    minions = {},  -- Track associated minions
    
    -- Enhanced buff properties
    buffColor = {1, 0, 0, 1},  -- Bright red for visibility
    buffMultiplier = 1.5,
    
    -- Visual properties
    color = {0.8, 0.1, 0.1, 1},  -- Dark red color for general
    defaultEnemyColor = {1, 1, 1, 1},
})

function General:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.buffRadius = self.buffRadius  -- Ensure buffRadius is set
    o.isGeneral = true  -- Ensure isGeneral flag is set
    return o
end

function General:init(x, y)
    Enemy.init(self, x, y)  -- Call parent's init
    self.minions = {}
    self.buffRadius = self.buffRadius or (150 * Constants.SCALE)  -- Ensure buffRadius is set
    self.generalId = tostring(math.random(1000000))  -- Add unique ID for debugging
    
    -- Enable debug temporarily for initialization
    print(string.format("General %s initialized at (%.1f, %.1f) with buffRadius %.1f", 
        self.generalId, x, y, self.buffRadius))
    
    return self
end

function General:update(dt)
    Enemy.update(self, dt)
    
    -- Debug print for this general's status
    if _G.debug then
        print(string.format("General %s at (%.1f, %.1f) with buffRadius %.1f", 
            self.generalId, self.x, self.y, self.buffRadius))
    end
    
    local buffedCount = 0
    for _, enemy in ipairs(_G.enemies) do
        if not enemy.isGeneral and not enemy.isBoss and enemy ~= self then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Debug distance check
            if _G.debug then
                print(string.format("General %s checking enemy at distance %.1f (buffRadius: %.1f)", 
                    self.generalId, distance, self.buffRadius))
            end
            
            if distance <= self.buffRadius then
                -- Track which general applied the buff
                if not enemy.isBuffed or enemy.buffedByGeneral ~= self.generalId then
                    if _G.debug then
                        print(string.format("General %s applying buff to enemy at distance %.1f", 
                            self.generalId, distance))
                    end
                    
                    -- Store original values if not already buffed
                    if not enemy.isBuffed then
                        enemy.originalSpeed = enemy.speed
                        enemy.originalDamage = enemy.damageAmount
                        enemy.originalColor = enemy.color and {unpack(enemy.color)} or {unpack(self.defaultEnemyColor)}
                        enemy.originalScale = enemy.scale or 1
                    end
                    
                    enemy.isBuffed = true
                    enemy.buffedByGeneral = self.generalId
                    enemy.buffedColor = {unpack(self.buffColor)}
                    enemy.color = enemy.buffedColor
                    enemy.speed = enemy.originalSpeed * self.buffMultiplier
                    enemy.damageAmount = enemy.originalDamage * self.buffMultiplier
                    enemy.scale = enemy.originalScale * 1.2
                    buffedCount = buffedCount + 1
                end
            else
                -- Only remove buff if this general applied it
                if enemy.isBuffed and enemy.buffedByGeneral == self.generalId then
                    if _G.debug then
                        print(string.format("General %s removing buff from enemy at distance %.1f", 
                            self.generalId, distance))
                    end
                    
                    enemy.isBuffed = false
                    enemy.buffedByGeneral = nil
                    enemy.speed = enemy.originalSpeed
                    enemy.damageAmount = enemy.originalDamage
                    enemy.color = enemy.originalColor
                    enemy.scale = enemy.originalScale
                    enemy.buffedColor = nil
                end
            end
        end
    end
    
    if _G.debug then
        print(string.format("General %s is buffing %d enemies", self.generalId, buffedCount))
    end
    
    -- Always show buff radius for generals
    love.graphics.setColor(1, 0, 0, 0.2)
    love.graphics.circle('line', self.x, self.y, self.buffRadius)
end

function General:hit(damage, isCritical)
    -- Call parent hit function
    local isDead = Enemy.hit(self, damage, isCritical)
    
    -- If general dies, remove buffs from all minions
    if isDead then
        for _, enemy in ipairs(_G.enemies) do
            if enemy.isBuffed then
                enemy.isBuffed = false
                enemy.speed = enemy.originalSpeed
                enemy.damageAmount = enemy.originalDamage
            end
        end
    end
    
    return isDead
end

-- Add debug command to toggle buff radius visualization
if _G.console then
    _G.console:addCommand('showbuffs', {
        desc = "Toggle general buff radius visualization",
        func = function()
            _G.debug = _G.debug or {}
            _G.debug.showBuffRadius = not _G.debug.showBuffRadius
            return "Buff radius visualization " .. (_G.debug.showBuffRadius and "enabled" or "disabled")
        end
    })
end

-- Add debug command to toggle general debug logging
if _G.console then
    _G.console:addCommand('debuggenerals', {
        desc = "Toggle general debug logging",
        func = function()
            _G.debug = _G.debug or {}
            _G.debug.generals = not _G.debug.generals
            return "General debug logging " .. (_G.debug.generals and "enabled" or "disabled")
        end
    })
end

return General

