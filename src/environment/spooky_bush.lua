local SpookyBush = {
    x = 0,
    y = 0,
    rotation = 0,
    scale = 1.0,
    -- Clustering parameters
    clusterRadius = 1000,  -- Maximum radius for a cluster
    minBushSpacing = 50    -- Minimum distance between bushes
}

function SpookyBush:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SpookyBush:init(x, y)
    self.x = x
    self.y = y
    self.rotation = math.random() * math.pi * 2
    self.scale = 0.5 + math.random() * 0.3  -- Smaller than trees
    print(string.format("Created spooky bush at position: %.1f, %.1f", x, y))
    return self
end

function SpookyBush.generateClusters(numClusters, bushesPerCluster, mapRadius)
    assert(numClusters > 0, "numClusters must be positive")
    assert(bushesPerCluster > 0, "bushesPerCluster must be positive")
    assert(mapRadius > 0, "mapRadius must be positive")

    local bushes = {}
    print("Starting spooky bush cluster generation...")
    
    for i = 1, numClusters do
        local clusterAngle = math.random() * math.pi * 2
        local clusterDist = math.random() * mapRadius
        local clusterX = math.cos(clusterAngle) * clusterDist
        local clusterY = math.sin(clusterAngle) * clusterDist
        
        for j = 1, bushesPerCluster do
            local attempts = 10
            while attempts > 0 do
                local angle = math.random() * math.pi * 2
                local dist = math.random() * SpookyBush.clusterRadius
                local x = clusterX + math.cos(angle) * dist
                local y = clusterY + math.sin(angle) * dist
                
                local validPosition = true
                for _, bush in ipairs(bushes) do
                    local dx = bush.x - x
                    local dy = bush.y - y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < SpookyBush.minBushSpacing then
                        validPosition = false
                        break
                    end
                end
                
                if validPosition then
                    table.insert(bushes, SpookyBush:new():init(x, y))
                    break
                end
                
                attempts = attempts - 1
            end
        end
    end
    
    return bushes
end

return SpookyBush