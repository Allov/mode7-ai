local DeadTree = {
    x = 0,
    y = 0,
    rotation = 0,
    scale = 1.0,
    -- Add clustering parameters
    clusterRadius = 2000,  -- Maximum radius for a cluster
    minTreeSpacing = 100   -- Minimum distance between trees
}

function DeadTree:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DeadTree:init(x, y)
    self.x = x
    self.y = y
    self.rotation = math.random() * math.pi * 2
    self.scale = 0.7 + math.random() * 0.6
    print(string.format("Created tree at position: %.1f, %.1f", x, y))  -- Debug print
    return self
end

function DeadTree.generateClusters(numClusters, treesPerCluster, mapRadius)
    assert(numClusters > 0, "numClusters must be positive")
    assert(treesPerCluster > 0, "treesPerCluster must be positive")
    assert(mapRadius > 0, "mapRadius must be positive")

    local trees = {}
    print("Starting cluster generation...")
    print(string.format("Parameters: clusters=%d, treesPerCluster=%d, mapRadius=%d", 
        numClusters, treesPerCluster, mapRadius))
    
    for i = 1, numClusters do
        local clusterAngle = math.random() * math.pi * 2
        local clusterDist = math.random() * mapRadius
        local clusterX = math.cos(clusterAngle) * clusterDist
        local clusterY = math.sin(clusterAngle) * clusterDist
        
        print(string.format("Generating cluster %d at (%.1f, %.1f)", i, clusterX, clusterY))
        
        local clusterTreeCount = 0
        for j = 1, treesPerCluster do
            local attempts = 10
            local treeAdded = false
            
            while attempts > 0 and not treeAdded do
                local angle = math.random() * math.pi * 2
                local dist = math.random() * DeadTree.clusterRadius
                local x = clusterX + math.cos(angle) * dist
                local y = clusterY + math.sin(angle) * dist
                
                local validPosition = true
                for _, tree in ipairs(trees) do
                    local dx = tree.x - x
                    local dy = tree.y - y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance < DeadTree.minTreeSpacing then
                        validPosition = false
                        break
                    end
                end
                
                if validPosition then
                    local newTree = DeadTree:new():init(x, y)
                    table.insert(trees, newTree)
                    treeAdded = true
                    clusterTreeCount = clusterTreeCount + 1
                end
                
                attempts = attempts - 1
            end
        end
        
        print(string.format("Cluster %d complete. Added %d trees", i, clusterTreeCount))
    end
    
    print(string.format("Cluster generation complete. Total trees: %d", #trees))
    return trees
end

return DeadTree


