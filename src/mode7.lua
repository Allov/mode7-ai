local Constants = require('src.constants')
local Rune = require('src.rune')
local GameData = require('src.gamedata')

local Mode7 = {
  texture = nil,
  shader = nil,
  skyTexture = nil,
  enemyTexture = nil,
  projectileTexture = nil,
  fogColor = {0.1, 0.2, 0.25},
  fogDampening = 0.9,
  fogAlpha = 0.93,
  -- Add camera light as first light, followed by static lights
  lightPositions = {{0, 0}, {300, 300}, {-300, -300}},  -- Camera light + static lights
  lightColors = {{1.0, 0.9, 0.7}, {1.0, 0.7, 0.3}, {1.0, 0.7, 0.3}},  -- Brighter white-ish for camera light
  lightRadii = {500, 300, 300},  -- Smaller radius for camera light
  ambientLight = {0.1, 0.1, 0.1},
}

function Mode7:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Mode7:load()
  -- Set filtering for ground texture
  self.texture = love.graphics.newImage('assets/images/ground.png')
  self.texture:setFilter('nearest', 'nearest')
  self.texture:setWrap('repeat', 'repeat')
  
  -- Set filtering for sky texture
  self.skyTexture = love.graphics.newImage('assets/images/sky.png')
  self.skyTexture:setFilter('nearest', 'nearest')
  self.skyTexture:setWrap('repeat', 'clamp')
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  self.shader:send('maxDistance', Constants.DRAW_DISTANCE)
  self.shader:send('fogColor', self.fogColor)
  self.shader:send('fogDampening', self.fogDampening)
  self.shader:send('fogAlpha', self.fogAlpha)
  self.shader:send('lightColors', unpack(self.lightColors))
  self.shader:send('lightRadii', unpack(self.lightRadii))
  self.shader:send('ambientLight', self.ambientLight)
  
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
  
  -- Create all canvas textures first
  -- Create more visible rune texture
  local runeCanvas = love.graphics.newCanvas(64, 64)  -- Increased from 32x32 to 64x64
  love.graphics.setCanvas(runeCanvas)
  love.graphics.clear()

  -- Draw larger glow effect
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.circle('fill', 32, 32, 30)  -- Outer glow

  -- Draw main rune circle
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 32, 32, 28)  -- Increased from 14 to 28

  -- Draw outline
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', 32, 32, 28)

  -- Draw rune symbols
  love.graphics.setLineWidth(4)  -- Thicker lines
  love.graphics.line(16, 32, 48, 32)  -- Horizontal line
  love.graphics.line(32, 16, 32, 48)  -- Vertical line

  love.graphics.setCanvas()
  self.runeTexture = runeCanvas
  self.runeTexture:setFilter('nearest', 'nearest')

  -- Load chest texture
  self.chestTexture = love.graphics.newImage("assets/images/chest.png")
  self.chestTexture:setFilter('nearest', 'nearest')

  -- Create glow texture
  local glowCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(glowCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 16)
  love.graphics.setCanvas()
  self.glowTexture = glowCanvas
  self.glowTexture:setFilter('nearest', 'nearest')

  -- Create temporary textures
  -- Regular enemy texture (triangle shape)
  local enemyCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(enemyCanvas)
  love.graphics.clear()
  love.graphics.setColor(0.8, 0.2, 0.2, 1)  -- Dark red
  love.graphics.polygon('fill', 16, 0, 32, 32, 0, 32)  -- Triangle
  -- Add white border
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(2)
  love.graphics.polygon('line', 16, 0, 32, 32, 0, 32)
  love.graphics.setCanvas()
  self.enemyTexture = enemyCanvas
  self.enemyTexture:setFilter('nearest', 'nearest')  -- Add filtering

  -- Elite enemy texture (diamond shape)
  local eliteCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(eliteCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 0.5, 0, 1)  -- Orange
  love.graphics.polygon('fill', 16, 0, 32, 16, 16, 32, 0, 16)  -- Diamond
  -- Add glowing border
  love.graphics.setColor(1, 0.8, 0, 1)  -- Golden
  love.graphics.setLineWidth(2)
  love.graphics.polygon('line', 16, 0, 32, 16, 16, 32, 0, 16)
  love.graphics.setCanvas()
  self.eliteTexture = eliteCanvas
  self.eliteTexture:setFilter('nearest', 'nearest')  -- Add filtering

  -- Boss texture (pentagonal shape with details)
  local bossCanvas = love.graphics.newCanvas(64, 64)  -- Larger canvas for more detail
  love.graphics.setCanvas(bossCanvas)
  love.graphics.clear()
  -- Main body
  love.graphics.setColor(0.7, 0, 0.7, 1)  -- Purple
  love.graphics.polygon('fill', 
    32, 0,   -- top
    64, 24,  -- right top
    52, 64,  -- right bottom
    12, 64,  -- left bottom
    0, 24    -- left top
  )
  -- Inner details
  love.graphics.setColor(1, 0, 1, 0.5)  -- Lighter purple
  love.graphics.polygon('fill',
    32, 10,  -- top
    52, 24,  -- right
    32, 54,  -- bottom
    12, 24   -- left
  )
  -- Glowing border
  love.graphics.setColor(1, 0.5, 1, 1)  -- Pink glow
  love.graphics.setLineWidth(3)
  love.graphics.polygon('line',
    32, 0,
    64, 24,
    52, 64,
    12, 64,
    0, 24
  )
  love.graphics.setCanvas()
  self.bossTexture = bossCanvas
  self.bossTexture:setFilter('nearest', 'nearest')  -- Add filtering

  local projectileCanvas = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(projectileCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 0, 1)  -- Yellow for projectile
  love.graphics.circle('fill', 8, 8, 8)
  love.graphics.setCanvas()
  self.projectileTexture = projectileCanvas
  self.projectileTexture:setFilter('nearest', 'nearest')  -- Add filtering
  
  -- Create experience orb texture
  local orbCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(orbCanvas)
  love.graphics.clear()
  
  -- Outer glow
  love.graphics.setColor(0, 1, 1, 0.5)  -- Cyan glow
  love.graphics.circle('fill', 16, 16, 14)
  
  -- Inner orb
  love.graphics.setColor(1, 1, 1, 1)  -- White core
  love.graphics.circle('fill', 16, 16, 8)
  
  -- Sparkle effect
  love.graphics.setColor(0, 1, 1, 1)  -- Bright cyan
  love.graphics.line(16, 4, 16, 28)   -- Vertical line
  love.graphics.line(4, 16, 28, 16)   -- Horizontal line
  
  love.graphics.setCanvas()
  self.orbTexture = orbCanvas
  self.orbTexture:setFilter('nearest', 'nearest')  -- Add filtering
end

function Mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runes)
  -- Update first light position to match camera
  self.lightPositions[1] = {camera.x, camera.y}
  
  love.graphics.setShader(self.shader)
  self.shader:send('cameraPos', {camera.x, camera.y})
  self.shader:send('cameraAngle', camera.angle)
  self.shader:send('lightPositions', unpack(self.lightPositions))
  self.shader:send('skyTexture', self.skyTexture)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.texture, 
    0, 0, 0, 
    love.graphics.getWidth() / self.texture:getWidth(), 
    love.graphics.getHeight() / self.texture:getHeight()
  )
  
  love.graphics.setShader()
  
  -- Add parameter validation with default empty tables
  enemies = enemies or {}
  projectiles = projectiles or {}
  experienceOrbs = experienceOrbs or {}
  chests = chests or {}
  runes = runes or {}

  -- Create a table of all objects to sort
  local allObjects = {}

  -- Add enemies to render list
  for _, enemy in ipairs(enemies) do
    local dx = enemy.x - camera.x
    local dy = enemy.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "enemy",
      object = enemy,
      distance = distance
    })
  end

  -- Add projectiles to render list
  for _, projectile in ipairs(projectiles) do
    local dx = projectile.x - camera.x
    local dy = projectile.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "projectile",
      object = projectile,
      distance = distance
    })
  end

  -- Add experience orbs to render list
  for _, orb in ipairs(experienceOrbs) do
    if orb.x and orb.y then
      local dx = orb.x - camera.x
      local dy = orb.y - camera.y
      local distance = math.sqrt(dx * dx + dy * dy)
      
      table.insert(allObjects, {
        type = "experienceOrb",
        object = orb,
        distance = distance
      })
    end
  end

  -- Add chests to render list
  for _, chest in ipairs(chests) do
    local dx = chest.x - camera.x
    local dy = chest.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "chest",
      object = chest,
      distance = distance
    })
  end

  -- Add runes to render list
  for _, rune in ipairs(runes) do
    local dx = rune.x - camera.x
    local dy = rune.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "rune",
      object = rune,
      distance = distance
    })
  end

  -- Add orbs to render list if player has an orbManager
  if _G.player and _G.player.orbManager then
    for _, orb in ipairs(_G.player.orbManager.orbs) do
      if orb.x and orb.y then  -- Only add if position exists
        local dx = orb.x - camera.x
        local dy = orb.y - camera.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        table.insert(allObjects, {
          type = "orb",
          object = orb,
          distance = distance
        })
      end
    end
  end

  -- Sort objects by distance (furthest first)
  table.sort(allObjects, function(a, b)
    return a.distance > b.distance
  end)

  -- Draw all objects in sorted order
  for _, obj in ipairs(allObjects) do
    if obj.type == "enemy" then
      local enemy = obj.object
      if enemy.isBoss then
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.bossTexture,
          scale = 400.0 * Constants.SPRITE_SCALE,
          heightScale = 2.0,
          useAngleScaling = true
        })
      elseif enemy.isElite then
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.eliteTexture,
          scale = 300.0 * Constants.SPRITE_SCALE,
          heightScale = 1.5,
          useAngleScaling = true
        })
      else
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.enemyTexture,
          scale = 200.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = true
        })
      end
    elseif obj.type == "projectile" then
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.projectileTexture,
        scale = 400.0 * Constants.SPRITE_SCALE,  -- Increased from 200.0 to 400.0
        useAngleScaling = false
      })
    elseif obj.type == "experienceOrb" then
      love.graphics.setColor(0, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.orbTexture,
        scale = 150.0 * Constants.SPRITE_SCALE,
        heightScale = 1.0,
        useAngleScaling = false
      })
    elseif obj.type == "chest" then
      -- Draw the chest texture
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.chestTexture,
        scale = 75.0 * Constants.SPRITE_SCALE,
        heightScale = 1.0,
        useAngleScaling = false
      })
      
      -- Add glow effect for unopened chests
      if not obj.object.isOpen then
        love.graphics.setColor(1, 1, 0, 0.5) -- Yellow glow
        self:drawSprite(obj.object, camera, {
          texture = self.glowTexture,
          scale = 100.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = false
        })
      end
    elseif obj.type == "rune" then
      local runeData = Rune.TYPES[obj.object.type]
      if runeData then
        local color = {
          runeData.color[1],
          runeData.color[2],
          runeData.color[3],
          1
        }
        
        self:drawSprite(obj.object, camera, {
          texture = self.runeTexture,  -- Changed from glowTexture to runeTexture
          scale = 50.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = false,
          color = color
        })
      end
    elseif obj.type == "orb" then
      love.graphics.setColor(0, 1, 1, 1) -- Cyan color
      self:drawSprite(obj.object, camera, {
        texture = self.orbTexture, -- We need to create this texture
        scale = 100.0 * Constants.SPRITE_SCALE,
        heightScale = 1.0,
        useAngleScaling = false
      })
    end
  end

  -- After drawing all objects but before HUD, add damage effect
  if _G.player.invulnerableTimer > 0 then
    -- Calculate alpha based on invulnerability timer
    local alpha = math.min(0.4, _G.player.invulnerableTimer / _G.player.invulnerableTime)
    
    -- Draw red overlay
    love.graphics.setColor(1, 0, 0, alpha)
    love.graphics.rectangle('fill', 0, 0, 
      love.graphics.getWidth(), 
      love.graphics.getHeight()
    )
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function Mode7:drawSprite(entity, camera, options)
    options = options or {}
    local texture = options.texture or self.enemyTexture
    local scale = options.scale or 6.0
    local heightScale = options.heightScale or 1.0
    local useAngleScaling = options.useAngleScaling or false
    local heightOffset = options.heightOffset or 0
    local color = options.color or {1, 1, 1, 1}  -- Default white
    
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Apply specified color
    love.graphics.setColor(unpack(color))
    
    -- Calculate screen position
    local dx = entity.x - camera.x
    local dy = entity.y - camera.y
    
    -- Transform to camera space
    local cosA = math.cos(camera.angle)
    local sinA = math.sin(camera.angle)
    local rx = dx * cosA - dy * sinA
    local ry = dx * sinA + dy * cosA
    
    -- Don't render if behind camera or too far
    if ry <= 0 or ry > Constants.DRAW_DISTANCE then 
        return 
    end
  
  -- Calculate screen position using proper FOV projection
  local fovRadians = math.rad(Constants.FOV)
  local tanHalfFOV = math.tan(fovRadians * 0.5)
  
  -- Project X coordinate using FOV
  local screenX = Constants.SCREEN_WIDTH/2 + 
                 (rx * Constants.SCREEN_HEIGHT) / (ry * tanHalfFOV)
  
  -- Calculate perspective scale using same FOV
  local perspectiveScale = (Constants.SCREEN_HEIGHT) / (ry * tanHalfFOV)
  local spriteScale = perspectiveScale * scale * 0.01
  
  -- Calculate ground position using the same projection as the shader
  local groundY = Constants.HORIZON_LINE + 
                 (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                 (Constants.CAMERA_HEIGHT / ry)
  
  -- Position sprite directly at ground level
  local screenY = groundY
  
  if heightOffset ~= 0 then
    -- Apply height offset after ground plane calculation
    screenY = screenY - (heightOffset * perspectiveScale)
  end

  -- Debug: Draw ground reference point
  -- love.graphics.setColor(1, 0, 0, 1)
  -- love.graphics.circle('fill', screenX, groundY, 2)
  
  -- Draw crosshair if this is the player's current target
  if _G.player and _G.player.currentTarget == entity then
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw targeting crosshair
    love.graphics.setColor(1, 0, 0, 0.8)  -- Red with some transparency
    
    -- Calculate crosshair size based on perspective
    local crosshairSize = 600 * perspectiveScale
    local lineLength = 200 * perspectiveScale
    local bracketSize = 300 * perspectiveScale
    
    -- Draw crosshair lines
    love.graphics.setLineWidth(4)  -- Thicker lines for visibility
    -- Horizontal lines
    love.graphics.line(screenX - crosshairSize, screenY, screenX - lineLength, screenY)
    love.graphics.line(screenX + lineLength, screenY, screenX + crosshairSize, screenY)
    -- Vertical lines
    love.graphics.line(screenX, screenY - crosshairSize, screenX, screenY - lineLength)
    love.graphics.line(screenX, screenY + lineLength, screenX, screenY + crosshairSize)
    
    -- Draw corner brackets
    -- Top-left
    love.graphics.line(screenX - bracketSize, screenY - bracketSize, screenX - bracketSize, screenY - bracketSize/2)
    love.graphics.line(screenX - bracketSize, screenY - bracketSize, screenX - bracketSize/2, screenY - bracketSize)
    -- Top-right
    love.graphics.line(screenX + bracketSize, screenY - bracketSize, screenX + bracketSize, screenY - bracketSize/2)
    love.graphics.line(screenX + bracketSize, screenY - bracketSize, screenX + bracketSize/2, screenY - bracketSize)
    -- Bottom-left
    love.graphics.line(screenX - bracketSize, screenY + bracketSize, screenX - bracketSize, screenY + bracketSize/2)
    love.graphics.line(screenX - bracketSize, screenY + bracketSize, screenX - bracketSize/2, screenY + bracketSize)
    -- Bottom-right
    love.graphics.line(screenX + bracketSize, screenY + bracketSize, screenX + bracketSize, screenY + bracketSize/2)
    love.graphics.line(screenX + bracketSize, screenY + bracketSize, screenX + bracketSize/2, screenY + bracketSize)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Restore original color
    love.graphics.setColor(r, g, b, a)
  end
  
  -- Draw the sprite with bottom aligned to ground
  love.graphics.draw(
    texture,
    screenX, screenY,
    0,  -- rotation
    spriteScale,  -- width scale
    spriteScale * heightScale,  -- height scale with multiplier
    texture:getWidth() / 2,     -- center horizontally
    texture:getHeight()         -- align bottom with ground
  )
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Draw health bar if entity has health
  if entity.health and entity.health > 0 then
    -- Calculate health bar dimensions
    local barWidth = texture:getWidth() * spriteScale
    local barHeight = 5 * spriteScale  -- Height of health bar
    local barY = screenY - (texture:getHeight() * spriteScale * heightScale / 2) - (barHeight * 2)  -- Position above sprite
    local barX = screenX - (barWidth / 2)
    
    -- Draw background (red)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)
    
    -- Draw health (green)
    local healthPercent = entity.health / (entity.isElite and (100 * entity.eliteMultiplier) or 100)
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle('fill', barX, barY, barWidth * healthPercent, barHeight)
    
    -- Draw border
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('line', barX, barY, barWidth, barHeight)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
  end
  
  -- Draw damage number if entity has one
  if entity.damageNumber then
    local num = entity.damageNumber
    -- Calculate damage number position
    local numDx = entity.x - camera.x
    local numDy = entity.y - camera.y
    local numRx = numDx * cosA - numDy * sinA
    local numRy = numDx * sinA + numDy * cosA
    
    -- Skip if behind camera
    if numRy > 0 then
      -- Calculate screen position with perspective
      local numScreenX = Constants.SCREEN_WIDTH/2 + 
                        (numRx * Constants.SCREEN_HEIGHT * 0.5) / numRy
      
      -- Adjust Y position based on floating height (INVERTED)
      local groundY = Constants.HORIZON_LINE + 
                     (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                     (Constants.CAMERA_HEIGHT / numRy)
      
      -- Calculate screen Y with NEGATIVE offset for upward movement
      local numScreenY = groundY - (num.age * 100) -- Move UP by using subtraction
      
      -- Draw damage number with color based on critical
      if num.isCritical then
        love.graphics.setColor(1, 0.5, 0, 1)  -- Orange-yellow for crits
      else
        love.graphics.setColor(1, 1, 0, 1)    -- Yellow for normal hits
      end
      
      love.graphics.push()
      love.graphics.translate(numScreenX, numScreenY)
      -- Bigger scale for crits
      local baseScale = num.isCritical and 2.0 or 1.5
      love.graphics.scale(baseScale, baseScale)
      love.graphics.printf(
        tostring(num.value),
        -50, -10,
        100,
        "center"
      )
      love.graphics.pop()
    end
  end
end

function Mode7:update(dt)
  -- Add subtle torch flicker
  local flickerIntensity = 1.0 + math.sin(love.timer.getTime() * 10) * 0.1
  local flickeringColor = {
    self.lightColor[1] * flickerIntensity,
    self.lightColor[2] * flickerIntensity,
    self.lightColor[3] * flickerIntensity
  }
  self.shader:send('lightColor', flickeringColor)
end

return Mode7


