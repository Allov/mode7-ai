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
    self:createMoonTexture()
    self:createFrostTextures()  -- Add frost textures creation
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

function TextureManager:createMoonTexture()
    print("Creating moon texture...")
    
    local moonCanvas = love.graphics.newCanvas(128, 128)
    love.graphics.setCanvas(moonCanvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Main moon circle with slight yellow tint
    love.graphics.setColor(0.95, 0.93, 0.88, 1)
    love.graphics.circle('fill', 64, 64, 60)
    
    -- Add subtle outer glow
    love.graphics.setColor(0.95, 0.93, 0.88, 0.2)
    love.graphics.circle('fill', 64, 64, 63)
    
    -- Add craters with slightly darker color
    love.graphics.setColor(0.85, 0.83, 0.78, 1)
    
    -- Large craters
    love.graphics.circle('fill', 45, 45, 15)  -- Top left
    love.graphics.circle('fill', 85, 75, 12)  -- Bottom right
    love.graphics.circle('fill', 60, 90, 14)  -- Bottom
    
    -- Medium craters
    love.graphics.circle('fill', 75, 40, 8)   -- Top right
    love.graphics.circle('fill', 35, 70, 10)  -- Bottom left
    love.graphics.circle('fill', 90, 50, 9)   -- Right
    
    -- Small craters
    love.graphics.circle('fill', 50, 65, 6)   -- Center
    love.graphics.circle('fill', 70, 60, 5)   -- Center right
    love.graphics.circle('fill', 40, 85, 4)   -- Bottom left
    love.graphics.circle('fill', 80, 30, 5)   -- Top right
    
    -- Add darker shading to craters
    love.graphics.setColor(0.75, 0.73, 0.68, 0.5)
    love.graphics.circle('fill', 45, 45, 12)  -- Top left
    love.graphics.circle('fill', 85, 75, 9)   -- Bottom right
    love.graphics.circle('fill', 60, 90, 11)  -- Bottom
    
    love.graphics.setCanvas()
    moonCanvas:setFilter('linear', 'linear')  -- Use linear filtering for smoother scaling
    self.textures.moon = moonCanvas
    
    return moonCanvas
end

function TextureManager:createFrostTextures()
    print("Creating frost textures...")
    
    -- Create frost particle texture (snowflake/ice crystal)
    local frostCanvas = love.graphics.newCanvas(64, 64)
    love.graphics.setCanvas(frostCanvas)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Ice blue color
    love.graphics.setColor(0.8, 0.9, 1.0, 1)
    
    -- Draw a snowflake pattern
    local center = 32
    local size = 28
    
    -- Draw main cross
    love.graphics.setLineWidth(3)
    for i = 0, 5 do
        local angle = i * math.pi / 3
        local x1 = center + math.cos(angle) * size
        local y1 = center + math.sin(angle) * size
        love.graphics.line(center, center, x1, y1)
        
        -- Draw smaller branches
        local branchSize = size * 0.4
        local branchAngle = math.pi / 6
        local midX = center + math.cos(angle) * (size * 0.6)
        local midY = center + math.sin(angle) * (size * 0.6)
        
        local branch1Angle = angle + branchAngle
        local branch2Angle = angle - branchAngle
        
        love.graphics.line(
            midX, midY,
            midX + math.cos(branch1Angle) * branchSize,
            midY + math.sin(branch1Angle) * branchSize
        )
        love.graphics.line(
            midX, midY,
            midX + math.cos(branch2Angle) * branchSize,
            midY + math.sin(branch2Angle) * branchSize
        )
    end
    
    -- Add center detail
    love.graphics.circle('fill', center, center, 4)
    
    love.graphics.setCanvas()
    frostCanvas:setFilter('linear', 'linear')
    self.textures.frost = frostCanvas
    
    -- Create frost nova texture (expanding ice wave)
    local novaCanvas = love.graphics.newCanvas(256, 256)
    love.graphics.setCanvas(novaCanvas)
    love.graphics.clear(0, 0, 0, 0)

    -- Draw expanding wave pattern
    local centerX, centerY = 128, 128
    local maxRadius = 120

    -- Draw ground frost pattern
    for radius = maxRadius, 0, -15 do
        local alpha = (radius / maxRadius) * 0.7  -- Reduced alpha for better blending
        love.graphics.setColor(0.8, 0.9, 1.0, alpha)
        
        -- Draw filled circle with gradient
        love.graphics.circle('fill', centerX, centerY, radius)
    end

    -- Add crystalline pattern
    love.graphics.setLineWidth(2)
    for i = 1, 16 do
        local angle = i * math.pi / 8
        local innerRadius = 20
        local outerRadius = maxRadius
        
        -- Draw ice cracks
        love.graphics.setColor(0.9, 0.95, 1.0, 0.5)
        local x1 = centerX + math.cos(angle) * innerRadius
        local y1 = centerY + math.sin(angle) * innerRadius
        local x2 = centerX + math.cos(angle) * outerRadius
        local y2 = centerY + math.sin(angle) * outerRadius
        love.graphics.line(x1, y1, x2, y2)
        
        -- Add smaller branching cracks
        local midRadius = outerRadius * 0.6
        local midX = centerX + math.cos(angle) * midRadius
        local midY = centerY + math.sin(angle) * midRadius
        local branchLength = outerRadius * 0.2
        
        love.graphics.setColor(0.9, 0.95, 1.0, 0.3)
        love.graphics.line(
            midX,
            midY,
            midX + math.cos(angle + 0.5) * branchLength,
            midY + math.sin(angle + 0.5) * branchLength
        )
        love.graphics.line(
            midX,
            midY,
            midX + math.cos(angle - 0.5) * branchLength,
            midY + math.sin(angle - 0.5) * branchLength
        )
    end

    love.graphics.setCanvas()
    novaCanvas:setFilter('linear', 'linear')
    self.textures.frostNova = novaCanvas
end

return TextureManager






