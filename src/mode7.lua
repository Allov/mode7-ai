local Constants = require('src.constants')
local Rune = require('src.rune')
local GameData = require('src.gamedata')

local Mode7 = {
  texture = nil,
  shader = nil,
  skyTexture = nil,
  enemyTexture = nil,
  projectileTexture = nil,
  fogColor = {0.1, 0.2, 0.25}
}

function Mode7:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Mode7:load()
  self.texture = love.graphics.newImage('assets/images/ground.png')
  self.texture:setWrap('repeat', 'repeat')
  
  -- Load sky texture
  self.skyTexture = love.graphics.newImage('assets/images/sky.png')
  self.skyTexture:setWrap('repeat', 'clamp')
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  self.shader:send('maxDistance', Constants.DRAW_DISTANCE)
  self.shader:send('fogColor', self.fogColor)
  
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
  
  -- Create temporary textures
  local enemyCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(enemyCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 0, 0, 1)  -- Red for enemy
  love.graphics.rectangle('fill', 0, 0, 32, 32)
  love.graphics.setCanvas()
  self.enemyTexture = enemyCanvas
  
  local projectileCanvas = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(projectileCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 0, 1)  -- Yellow for projectile
  love.graphics.circle('fill', 8, 8, 8)
  love.graphics.setCanvas()
  self.projectileTexture = projectileCanvas
  
  -- Create experience orb texture
  local orbCanvas = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(orbCanvas)
  love.graphics.clear()
  love.graphics.setColor(0, 1, 1, 1)  -- Cyan for experience orbs
  love.graphics.circle('fill', 8, 8, 8)
  love.graphics.setColor(1, 1, 1, 1)  -- White inner glow
  love.graphics.circle('fill', 8, 8, 4)
  love.graphics.setCanvas()
  self.orbTexture = orbCanvas

  -- Load chest texture
  self.chestTexture = love.graphics.newImage("assets/images/chest.png")

  -- Load boss texture
  self.bossTexture = love.graphics.newImage('assets/images/boss.png')

  -- Create glow texture
  local glowCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(glowCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 16)
  love.graphics.setCanvas()
  self.glowTexture = glowCanvas

  -- Create rune texture
  local runeCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(runeCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('line', 16, 16, 14)
  love.graphics.line(8, 16, 24, 16)  -- Simple rune symbol
  love.graphics.line(16, 8, 16, 24)
  love.graphics.setCanvas()
  self.runeTexture = runeCanvas
end

function Mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runes)
  -- Add parameter validation with default empty tables
  enemies = enemies or {}
  projectiles = projectiles or {}
  experienceOrbs = experienceOrbs or {}
  chests = chests or {}
  runes = runes or {}
  
  -- Update shader with current camera height including bob
  self.shader:send('cameraHeight', camera.z)
  self.shader:send('cameraPos', {camera.x, camera.y})
  self.shader:send('cameraAngle', camera.angle)
  
  -- Draw sky first
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.skyTexture, 0, 0, 0, 
    love.graphics.getWidth() / self.skyTexture:getWidth(),
    love.graphics.getHeight() / self.skyTexture:getHeight())
  
  -- Draw ground with shader - using screen dimensions
  love.graphics.setShader(self.shader)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.texture, 0, 0, 0, 
    love.graphics.getWidth() / self.texture:getWidth(),
    love.graphics.getHeight() / self.texture:getHeight())
  love.graphics.setShader()
  
  -- Create a table of all objects to sort
  local allObjects = {}

  -- Add enemies
  for _, enemy in ipairs(enemies) do
    if enemy.distanceTo then  -- Check if method exists
      table.insert(allObjects, {
        type = "enemy",
        object = enemy,
        distance = enemy:distanceTo(camera.x, camera.y)
      })
    end
  end

  -- Add projectiles
  for _, proj in ipairs(projectiles) do
    if proj.distanceTo then  -- Check if method exists
      table.insert(allObjects, {
        type = "projectile",
        object = proj,
        distance = proj:distanceTo(camera.x, camera.y)
      })
    end
  end

  -- Add runes
  for _, rune in ipairs(runes) do
    if rune.distanceTo then  -- Check if method exists
      table.insert(allObjects, {
        type = "rune",
        object = rune,
        distance = rune:distanceTo(camera.x, camera.y)
      })
    end
  end

  -- Sort objects by distance (furthest first)
  table.sort(allObjects, function(a, b)
    return a.distance > b.distance
  end)

  -- Draw all objects in sorted order
  for _, obj in ipairs(allObjects) do
    if obj.type == "enemy" then
      -- Set color for elite enemies
      if obj.isElite then
        love.graphics.setColor(obj.object.eliteColor)
      else
        love.graphics.setColor(1, 1, 1, 1)
      end
      
      -- Scale down by 50% (200 instead of 400 for regular enemies)
      self:drawSprite(obj.object, camera, {
        texture = obj.isBoss and self.bossTexture or self.enemyTexture,
        scale = (obj.isBoss and 400.0) or (obj.isElite and 300.0) or 200.0,  -- 50% reduction
        heightScale = 1.5,  -- Keep the tall appearance
        useAngleScaling = true
      })
      
      -- Reset color
      love.graphics.setColor(1, 1, 1, 1)
      
    elseif obj.type == "projectile" then
      self:drawSprite(obj.object, camera, {
        texture = self.projectileTexture,
        scale = 200.0,
        useAngleScaling = false
      })
      
    elseif obj.type == "experienceOrb" then
      -- Set color for experience orbs
      love.graphics.setColor(0, 1, 1, 1)  -- Cyan color
      
      self:drawSprite(obj.object, camera, {
        texture = self.orbTexture,
        scale = 100.0,  -- Smaller scale for orbs
        heightScale = 1.0,
        useAngleScaling = false
      })
      
      -- Reset color
      love.graphics.setColor(1, 1, 1, 1)
      
    elseif obj.type == "chest" then
      self:drawSprite(obj.object, camera, {
        texture = self.chestTexture,
        scale = 30.0,
        useAngleScaling = false
      })
    elseif obj.type == "rune" then
      -- Get rune data for color
      local runeData = GameData.RUNE_TYPES[obj.object.type]
      if runeData then
        -- Set the rune's color
        love.graphics.setColor(runeData.color[1], runeData.color[2], runeData.color[3], 1)
        
        -- Draw the rune
        self:drawSprite(obj.object, camera, {
          texture = self.runeTexture,
          scale = 100.0,  -- Much smaller now
          heightScale = 1.0,
          useAngleScaling = false
        })
        
        -- Draw glow effect
        local glowSize = 1.0 + math.sin(obj.object.glowPhase) * 0.2
        love.graphics.setColor(runeData.color[1], runeData.color[2], runeData.color[3], 0.5)
        self:drawSprite(obj.object, camera, {
          texture = self.glowTexture,
          scale = 150.0 * glowSize,  -- Much smaller glow
          heightScale = 1.0,
          useAngleScaling = false
        })
      end
      
      -- Reset color
      love.graphics.setColor(1, 1, 1, 1)
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
  local heightScale = options.heightScale or 1.0  -- New height scale parameter
  local useAngleScaling = options.useAngleScaling or false
  local color = options.color or {1, 1, 1, 1}
  local heightOffset = options.heightOffset or 0
  
  -- Adjust camera offset for X axis
  local dx = entity.x - camera.x
  local dy = entity.y - camera.y
  
  -- Transform to camera space using same rotation as shader
  local cosA = math.cos(camera.angle)
  local sinA = math.sin(camera.angle)
  local rx = dx * cosA - dy * sinA
  local ry = dx * sinA + dy * cosA
  
  -- Don't render if behind camera or too far
  if ry <= 0 or ry > Constants.DRAW_DISTANCE then return end
  
  -- Calculate perspective scale with separate height scaling
  local perspectiveScale = Constants.SCREEN_HEIGHT / (2.0 * ry)
  local spriteScale = perspectiveScale * scale * 0.01
  
  -- Calculate screen position
  local screenX = Constants.SCREEN_WIDTH/2 + (rx * Constants.SCREEN_HEIGHT * 0.5) / ry
  
  -- Calculate ground position for proper Y placement
  local groundY = Constants.HORIZON_LINE + 
                 (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                 (Constants.CAMERA_HEIGHT / ry)
  
  -- Position sprite above ground position, applying height scale
  local screenY = groundY - (texture:getHeight() * spriteScale * heightScale / 2) - heightOffset
  
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
  
  -- Apply color if specified
  love.graphics.setColor(unpack(color))
  
  -- Draw the sprite with separate width and height scaling
  love.graphics.draw(
    texture,
    screenX, screenY,
    0,  -- rotation
    spriteScale,  -- width scale
    spriteScale * heightScale,  -- height scale with multiplier
    texture:getWidth() / 2,
    texture:getHeight() / 2
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

return Mode7


