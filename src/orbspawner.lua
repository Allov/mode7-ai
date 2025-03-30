local OrbSpawner = {
    -- Available orb types
    orbTypes = {
        "lightning",
        "pulse",
        "fire",
        -- Add more orb types here as they're implemented
    },
    
    -- Spawn settings
    maxOrbsPerPlayer = 10,
    
    -- References
    player = nil,
    
    -- Upgrade costs (experience needed)
    baseUpgradeCost = 100,
    upgradeCostMultiplier = 1.5,
}

function OrbSpawner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OrbSpawner:init(player)
    self.player = player
    
    -- Initialize OrbManager if it doesn't exist
    if not self.player.orbManager then
        self.player.orbManager = require('src.orbmanager'):new():init(self.player)
    end
    
    return self
end

function OrbSpawner:getUpgradeCost(currentRank)
    return math.floor(self.baseUpgradeCost * (self.upgradeCostMultiplier ^ (currentRank - 1)))
end

function OrbSpawner:canAddOrb(orbType)
    -- Check if player has room for more orbs
    if #self.player.orbManager.orbs >= self.maxOrbsPerPlayer then
        return false, "Maximum orbs reached"
    end
    
    -- Check if orb type exists
    local found = false
    for _, validType in ipairs(self.orbTypes) do
        if validType == orbType then
            found = true
            break
        end
    end
    
    if not found then
        return false, "Invalid orb type"
    end
    
    return true, nil
end

function OrbSpawner:addOrb(orbType)
    local canAdd, error = self:canAddOrb(orbType)
    if not canAdd then
        return false, error
    end
    
    -- Try to add the orb
    local success = self.player.orbManager:addOrb(orbType)
    if success then
        return true, nil
    end
    
    return false, "Failed to add orb"
end

function OrbSpawner:upgradeOrb(orbType)
    -- Find the orb
    for _, orb in ipairs(self.player.orbManager.orbs) do
        if orb.type == orbType then
            -- Check if orb is at max rank
            if orb.rank >= orb.maxRank then
                return false, "Orb is at maximum rank"
            end
            
            -- Calculate upgrade cost
            local cost = self:getUpgradeCost(orb.rank)
            
            -- Check if player has enough experience
            if self.player.experience >= cost then
                -- Deduct experience and upgrade
                self.player.experience = self.player.experience - cost
                orb.rank = orb.rank + 1
                print(string.format("Upgraded %s orb to rank %d", orbType, orb.rank))
                return true, nil
            else
                return false, "Not enough experience"
            end
        end
    end
    
    return false, "Orb not found"
end

function OrbSpawner:removeOrb(orbType)
    return self.player.orbManager:removeOrb(orbType)
end

function OrbSpawner:listAvailableOrbs()
    local available = {}
    for _, orbType in ipairs(self.orbTypes) do
        table.insert(available, {
            type = orbType,
            owned = false,
            rank = 0
        })
    end
    
    -- Update owned status and rank
    for _, orb in ipairs(self.player.orbManager.orbs) do
        for _, available in ipairs(available) do
            if available.type == orb.type then
                available.owned = true
                available.rank = orb.rank
                break
            end
        end
    end
    
    return available
end

return OrbSpawner

