local PlayerArms = {
    bobPhase = 0,
    bobFrequency = 8,
    bobAmplitude = 15,  -- Increased bob amplitude
    armColor = {0.8, 0.8, 0.8},
    handColor = {0.95, 0.85, 0.65},  -- Beige color for hands
    fireballColor = {1.0, 0.4, 0.0},
    fireballGlowColor = {1.0, 0.8, 0.0},
    fireballTime = 0,
    armAngle = 0.3,  -- ~17 degrees in radians
    fireballAlpha = 1.0  -- Add alpha tracking for fade effect
}

function PlayerArms:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    -- Create arm textures
    self:createArmTextures()
    return o
end

function PlayerArms:createArmTextures()
    -- Create left arm texture (now larger)
    local leftArmCanvas = love.graphics.newCanvas(64, 192)  -- Doubled size
    love.graphics.setCanvas(leftArmCanvas)
    love.graphics.clear()
    
    -- Draw pixelated arm shape extending to bottom
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('fill', 16, 64, 32, 128)  -- Main arm (doubled)
    
    -- Draw beige hand
    love.graphics.setColor(0.95, 0.85, 0.65, 1)
    -- Palm
    love.graphics.rectangle('fill', 12, 48, 40, 20)
    -- Thumb
    love.graphics.rectangle('fill', 8, 52, 8, 12)
    -- Fingers reaching towards center
    love.graphics.rectangle('fill', 16, 40, 8, 12)   -- Index
    love.graphics.rectangle('fill', 28, 36, 8, 16)  -- Middle
    love.graphics.rectangle('fill', 40, 40, 8, 12)  -- Ring
    
    -- Add shading to arm
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle('fill', 20, 68, 8, 120)  -- Highlight
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle('fill', 36, 68, 8, 120)  -- Shadow
    
    -- Add hand shading
    love.graphics.setColor(1, 0.9, 0.7, 1)
    love.graphics.rectangle('fill', 16, 52, 8, 12)
    love.graphics.setColor(0.85, 0.75, 0.55, 1)
    love.graphics.rectangle('fill', 40, 52, 8, 12)
    
    love.graphics.setCanvas()
    self.leftArmTexture = leftArmCanvas
    self.leftArmTexture:setFilter('nearest', 'nearest')
    
    -- Create right arm texture (mirrored design)
    local rightArmCanvas = love.graphics.newCanvas(64, 192)
    love.graphics.setCanvas(rightArmCanvas)
    love.graphics.clear()
    
    -- Draw pixelated arm shape extending to bottom
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle('fill', 16, 64, 32, 128)
    
    -- Draw beige hand
    love.graphics.setColor(0.95, 0.85, 0.65, 1)
    -- Palm
    love.graphics.rectangle('fill', 12, 48, 40, 20)
    -- Thumb
    love.graphics.rectangle('fill', 48, 52, 8, 12)
    -- Fingers reaching towards center
    love.graphics.rectangle('fill', 40, 40, 8, 12)  -- Index
    love.graphics.rectangle('fill', 28, 36, 8, 16)  -- Middle
    love.graphics.rectangle('fill', 16, 40, 8, 12)  -- Ring
    
    -- Add shading
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle('fill', 20, 68, 8, 120)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.rectangle('fill', 36, 68, 8, 120)
    
    -- Add hand shading
    love.graphics.setColor(1, 0.9, 0.7, 1)
    love.graphics.rectangle('fill', 16, 52, 8, 12)
    love.graphics.setColor(0.85, 0.75, 0.55, 1)
    love.graphics.rectangle('fill', 40, 52, 8, 12)
    
    love.graphics.setCanvas()
    self.rightArmTexture = rightArmCanvas
    self.rightArmTexture:setFilter('nearest', 'nearest')
    
    -- Create larger fireball texture
    local fireballCanvas = love.graphics.newCanvas(128, 128)  -- Doubled size
    love.graphics.setCanvas(fireballCanvas)
    love.graphics.clear()
    
    -- Draw outer glow
    love.graphics.setColor(1, 0.5, 0, 0.5)
    love.graphics.circle('fill', 64, 64, 56)
    
    -- Draw middle layer
    love.graphics.setColor(1, 0.3, 0, 0.8)
    love.graphics.circle('fill', 64, 64, 40)
    
    -- Draw core
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.circle('fill', 64, 64, 24)
    
    -- Add pixelated flame details
    for i = 1, 12 do  -- More flame details
        local angle = (i * math.pi / 6) + (self.fireballTime * 0.1)
        local x = 64 + math.cos(angle) * 32
        local y = 64 + math.sin(angle) * 32
        love.graphics.setColor(1, 1, 0.8, 0.9)
        love.graphics.rectangle('fill', x-4, y-4, 8, 8)
    end
    
    love.graphics.setCanvas()
    self.fireballTexture = fireballCanvas
    self.fireballTexture:setFilter('nearest', 'nearest')
end

function PlayerArms:update(dt, player)
    -- Update bob animation
    if math.abs(player.forward) > 0.01 or math.abs(player.strafe) > 0.01 then
        self.bobPhase = self.bobPhase + dt * self.bobFrequency
        
        if self.bobPhase > math.pi then
            self.bobPhase = math.pi - (self.bobPhase - math.pi)
            self.bobFrequency = -self.bobFrequency
        elseif self.bobPhase < 0 then
            self.bobPhase = -self.bobPhase
            self.bobFrequency = -self.bobFrequency
        end
    else
        if math.abs(self.bobPhase) > 0.01 then
            self.bobPhase = self.bobPhase * 0.9
        else
            self.bobPhase = 0
        end
        self.bobFrequency = math.abs(self.bobFrequency)
    end

    -- Update fireball animation and alpha
    self.fireballTime = self.fireballTime + dt * 5
    
    -- Update fireball alpha based on player's shoot cooldown
    if player.shootTimer > 0 then
        -- Calculate alpha based on cooldown progress
        self.fireballAlpha = 1.0 - (player.shootTimer / player.shootCooldown)
    else
        self.fireballAlpha = 1.0
    end
end

function PlayerArms:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate bob offsets
    local verticalBob = math.sin(self.bobPhase) * self.bobAmplitude
    local horizontalBob = math.cos(self.bobPhase) * (self.bobAmplitude * 0.5)
    
    -- Draw left arm
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.leftArmTexture,
        screenWidth * 0.3 - horizontalBob,
        screenHeight * 0.55 + verticalBob,
        self.armAngle,
        4,
        4,
        32,
        0
    )
    
    -- Draw right arm
    love.graphics.draw(
        self.rightArmTexture,
        screenWidth * 0.7 + horizontalBob,
        screenHeight * 0.55 + verticalBob,
        -self.armAngle,
        -4,
        4,
        32,
        0
    )
    
    -- Draw fireball with alpha fade
    local fireballX = screenWidth * 0.5 + (horizontalBob * 0.2)
    local fireballY = screenHeight * 0.8 + verticalBob
    
    love.graphics.setColor(1, 1, 1, self.fireballAlpha)  -- Apply alpha to fireball
    love.graphics.draw(
        self.fireballTexture,
        fireballX,
        fireballY,
        self.fireballTime * 0.5,
        2.4,
        2.4,
        64,
        64
    )
end

return PlayerArms












