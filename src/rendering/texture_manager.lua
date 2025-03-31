local TextureManager = {}

function TextureManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.textures = {}  -- Initialize textures table
    return o
end

function TextureManager:load()
    -- Create all textures
    self.textures = {}
    
    -- Create dead tree texture first to ensure it exists
    self:createDeadTreeTexture()
    self:createSpookyBushTexture()
end

function TextureManager:getTexture(name)
    return self.textures[name]
end

function TextureManager:createDeadTreeTexture()
    -- Debug print
    print("Creating dead tree texture...")
    
    local treeCanvas = love.graphics.newCanvas(128, 192)
    love.graphics.setCanvas(treeCanvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Almost black colors
    love.graphics.setColor(0.08, 0.07, 0.06, 1)  -- Very dark grey for trunk
    love.graphics.rectangle('fill', 59, 32, 8, 160)  -- Thinner trunk for more skeletal look
    
    -- Branches even darker and spikier
    love.graphics.setColor(0.06, 0.05, 0.04, 1)  -- Almost black
    
    -- Upper branches (more aggressive angles)
    love.graphics.polygon('fill',
        64, 60,   
        20, 30,   -- Extended spike tip
        64, 70    
    )
    love.graphics.polygon('fill',
        64, 90,
        15, 65,   -- More extreme angle
        64, 100
    )
    -- Right upper branches
    love.graphics.polygon('fill',
        64, 75,
        108, 45,  -- Extended spike
        64, 85
    )
    love.graphics.polygon('fill',
        64, 110,
        105, 85,  -- Sharper angle
        64, 120
    )
    
    -- Middle branches (extremely aggressive angles)
    love.graphics.polygon('fill',
        64, 130,
        10, 105,  -- Even longer spike
        64, 140
    )
    love.graphics.polygon('fill',
        64, 130,
        118, 105, -- Even longer spike
        64, 140
    )
    
    -- Additional middle spikes for more horror
    love.graphics.polygon('fill',
        64, 125,
        30, 115,
        64, 135
    )
    love.graphics.polygon('fill',
        64, 125,
        98, 115,
        64, 135
    )
    
    -- Lower branches (extremely spiky)
    love.graphics.polygon('fill',
        64, 150,
        5, 130,   -- Extra long spike
        64, 160
    )
    love.graphics.polygon('fill',
        64, 150,
        123, 130, -- Extra long spike
        64, 160
    )
    
    -- Additional lower spikes
    love.graphics.polygon('fill',
        64, 155,
        25, 145,
        64, 165
    )
    love.graphics.polygon('fill',
        64, 155,
        103, 145,
        64, 165
    )
    
    -- Bottom spikes (more aggressive downward angle)
    love.graphics.polygon('fill',
        64, 170,
        15, 185,  -- More extreme downward angle
        64, 180
    )
    love.graphics.polygon('fill',
        64, 170,
        113, 185, -- More extreme downward angle
        64, 180
    )
    
    -- Spiky crown (even more menacing)
    love.graphics.setColor(0.04, 0.03, 0.02, 1)  -- Nearly black
    love.graphics.polygon('fill',
        64, 0,     -- Top center
        30, 45,    -- More extreme bottom left
        45, 20,    -- Sharper inner left
        64, 35,    -- Lower center point
        83, 20,    -- Sharper inner right
        98, 45,    -- More extreme bottom right
        64, 0      -- Back to top
    )
    
    -- Additional crown spikes
    love.graphics.polygon('fill', 30, 45, 15, 25, 45, 20)  -- Extended left spike
    love.graphics.polygon('fill', 98, 45, 113, 25, 83, 20) -- Extended right spike
    
    -- Additional small crown spikes
    love.graphics.polygon('fill', 64, 0, 54, 15, 64, 10)   -- Top left spike
    love.graphics.polygon('fill', 64, 0, 74, 15, 64, 10)   -- Top right spike
    
    -- Twisted roots (more aggressive)
    love.graphics.setColor(0.07, 0.06, 0.05, 1)  -- Very dark grey
    love.graphics.polygon('fill', 64, 185, 45, 192, 64, 188)  -- Extended left root
    love.graphics.polygon('fill', 64, 185, 83, 192, 64, 188)  -- Extended right root
    
    -- Additional small root spikes
    love.graphics.polygon('fill', 64, 188, 55, 192, 64, 190)  -- Small left root
    love.graphics.polygon('fill', 64, 188, 73, 192, 64, 190)  -- Small right root
    
    love.graphics.setCanvas()
    treeCanvas:setFilter('nearest', 'nearest')
    self.textures.deadTree = treeCanvas
    
    return treeCanvas
end

function TextureManager:createSpookyBushTexture()
    print("Creating spooky bush texture...")
    
    local bushCanvas = love.graphics.newCanvas(96, 96)
    love.graphics.setCanvas(bushCanvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Base color (very dark green-grey)
    love.graphics.setColor(0.06, 0.08, 0.05, 1)
    
    -- Solid base at the bottom
    love.graphics.rectangle('fill', 24, 72, 48, 24)  -- Flat bottom third
    
    -- Main bush body (more dense in middle, spiky at top)
    local centerX, centerY = 48, 36  -- Moved center point up
    local points = {}
    
    -- Create bottom points (wider, flatter)
    table.insert(points, 24)  -- left bottom
    table.insert(points, 72)
    table.insert(points, 72)  -- right bottom
    table.insert(points, 72)
    
    -- Create spiky top points
    local spikes = 8  -- Number of major spikes for top half
    for i = 1, spikes do
        local angle = (i / spikes) * math.pi - math.pi/2  -- Start from top
        local radius = 25 + math.random() * 15  -- Varying radius
        local x = centerX + math.cos(angle) * radius
        local y = centerY + math.sin(angle) * math.max(0, radius)  -- Prevent downward spikes
        table.insert(points, x)
        table.insert(points, y)
    end
    
    love.graphics.polygon('fill', points)
    
    -- Add darker thorny spikes (only on top half)
    love.graphics.setColor(0.04, 0.05, 0.03, 1)  -- Even darker for thorns
    for i = 1, 12 do
        local angle = (math.random() * math.pi) - math.pi/2  -- Only top half
        local dist = 15 + math.random() * 20
        local x1 = centerX + math.cos(angle) * 15
        local y1 = centerY + math.sin(angle) * 15
        local x2 = centerX + math.cos(angle) * dist
        local y2 = centerY + math.sin(angle) * dist
        
        -- Make thorns triangular
        local perpAngle = angle + math.pi/2
        local thornWidth = 2 + math.random() * 3
        local x3 = x2 + math.cos(perpAngle) * thornWidth
        local x4 = x2 - math.cos(perpAngle) * thornWidth
        local y3 = y2 + math.sin(perpAngle) * thornWidth
        local y4 = y2 - math.sin(perpAngle) * thornWidth
        
        love.graphics.polygon('fill', x1, y1, x3, y3, x4, y4)
    end
    
    -- Add some smaller thorns (top half only)
    for i = 1, 16 do
        local angle = (math.random() * math.pi) - math.pi/2  -- Only top half
        local dist = 10 + math.random() * 15
        local x1 = centerX + math.cos(angle) * 10
        local y1 = centerY + math.sin(angle) * 10
        local x2 = centerX + math.cos(angle) * dist
        local y2 = centerY + math.sin(angle) * dist
        
        local perpAngle = angle + math.pi/2
        local thornWidth = 1 + math.random() * 2
        local x3 = x2 + math.cos(perpAngle) * thornWidth
        local x4 = x2 - math.cos(perpAngle) * thornWidth
        local y3 = y2 + math.sin(perpAngle) * thornWidth
        local y4 = y2 - math.sin(perpAngle) * thornWidth
        
        love.graphics.polygon('fill', x1, y1, x3, y3, x4, y4)
    end
    
    love.graphics.setCanvas()
    bushCanvas:setFilter('nearest', 'nearest')
    self.textures.spookyBush = bushCanvas
    
    return bushCanvas
end

return TextureManager



