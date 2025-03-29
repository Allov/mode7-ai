local Constants = require('src.constants')
local Rune = require('src.rune')

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
  experienceOrbs = experienceOrbs or {}
  chests = chests or {}
  runes = runes or {}
  
  -- Update shader with current camera height including bob
  self.shader:send('cameraHeight', camera.z)
  
  -- Draw sky with spherical projection
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Calculate sky parameters
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local skyHeight = Constants.HORIZON_LINE
  local skyTextureWidth = self.skyTexture:getWidth()
  local skyTextureHeight = self.skyTexture:getHeight()
  
  -- Draw sky in vertical strips
  local numStrips = 32  -- Increase for smoother projection
  local stripWidth = screenWidth / numStrips
  
  for i = 0, numStrips - 1 do
    local x = i * stripWidth
    local screenX = x + stripWidth / 2
    
    -- Calculate angle for this strip relative to camera view
    local angleOffset = math.atan2(screenX - screenWidth/2, screenWidth/2)
    local totalAngle = camera.angle + angleOffset
    
    -- Calculate UV coordinates with wraparound
    local u = (totalAngle / (math.pi * 2)) * skyTextureWidth
    local sourceX = u % skyTextureWidth
    
    -- Draw the sky strip
    love.graphics.draw(
      self.skyTexture,
      x, 0,                    -- Position
      0,                       -- Rotation
      stripWidth / skyTextureWidth, skyHeight / skyTextureHeight,  -- Scale
      sourceX, 0,              -- Source quad x, y
      1, skyTextureHeight     -- Source quad width, height
    )
  end

  -- Draw ground plane with shader
  love.graphics.setShader(self.shader)
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Send camera data to shader
  self.shader:send('cameraPos', {camera.x, camera.y})
  self.shader:send('cameraAngle', camera.angle)
  
  love.graphics.draw(
    self.texture,
    0, 0,
    0,
    Constants.SCREEN_WIDTH / self.texture:getWidth(),
    Constants.SCREEN_HEIGHT / self.texture:getHeight()
  )
  
  love.graphics.setShader()
  
  -- Draw sprites
  if enemies then
    for _, enemy in ipairs(enemies) do
      -- Check if enemy is a boss or elite
      local isBoss = enemy.chargeSpeed ~= nil  -- Boss-specific property
      
      -- Set color for elite enemies
      if enemy.isElite then
        love.graphics.setColor(enemy.eliteColor)
      end
      
      self:drawSprite(enemy, camera, {
        texture = isBoss and self.bossTexture or self.enemyTexture,
        scale = (isBoss and 12.0) or (enemy.isElite and 9.0) or 6.0,  -- Larger scale for elites
        useAngleScaling = true
      })
      
      -- Reset color
      love.graphics.setColor(1, 1, 1, 1)
      
      -- Debug visualization for elite enemies
      if enemy.isElite then
        love.graphics.setColor(1, 0.5, 0, 0.3)
        love.graphics.circle('line', 
          enemy.x - camera.x, 
          enemy.y - camera.y, 
          enemy.radius)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end
  end
  
  if projectiles then
    for _, projectile in ipairs(projectiles) do
      self:drawSprite(projectile, camera, {
        texture = self.projectileTexture,
        scale = 4.0,
        useAngleScaling = false
      })
    end
  end

  -- Render experience orbs
  for _, orb in ipairs(experienceOrbs) do
    self:drawSprite(orb, camera, {
      texture = self.orbTexture,
      scale = 3.0,
      useAngleScaling = false
    })
  end

  -- Render chests
  for _, chest in ipairs(chests) do
    self:drawSprite(chest, camera, {
      texture = self.chestTexture,
      scale = 3.0,  -- Changed from 6.0 to 3.0 (50% smaller)
      useAngleScaling = false
    })
  end

  -- Render runes
  for _, rune in ipairs(runes) do
    local runeData = Rune.TYPES[rune.type]
    if runeData then
      -- Draw glow effect first
      self:drawSprite(rune, camera, {
        texture = self.glowTexture,  -- We'll need to create this
        scale = 8.0,
        useAngleScaling = false,
        color = {runeData.color[1], runeData.color[2], runeData.color[3], 
                 0.5 + math.sin(rune.glowPhase) * 0.2}
      })
      
      -- Draw rune symbol
      self:drawSprite(rune, camera, {
        texture = self.runeTexture,  -- We'll need to create this
        scale = 6.0,
        useAngleScaling = false,
        heightOffset = math.sin(rune.glowPhase) * 10  -- Float effect
      })
    end
  end
end

function Mode7:drawSprite(entity, camera, options)
  options = options or {}
  local texture = options.texture or self.enemyTexture
  local scale = options.scale or 6.0
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
  
  -- Clamp minimum distance to prevent extreme scaling
  local MIN_RENDER_DISTANCE = 50
  ry = math.max(ry, MIN_RENDER_DISTANCE)
  
  -- Calculate sprite scale based on distance
  local spriteScale = (Constants.CAMERA_HEIGHT / ry) * scale
  
  -- Match shader's perspective transformation exactly
  local screenX = Constants.SCREEN_WIDTH/2 + 
                  (rx * Constants.SCREEN_HEIGHT * 0.5) / ry
  
  -- Calculate ground position using same perspective
  local groundY = Constants.HORIZON_LINE + 
                  (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                  (Constants.CAMERA_HEIGHT / ry)
  
  -- Position sprite above ground position by half its height, plus any offset
  local screenY = groundY - (texture:getHeight() * spriteScale / 2) - heightOffset
  
  -- Apply color if specified
  love.graphics.setColor(unpack(color))
  
  -- Draw the sprite
  love.graphics.draw(
    texture,
    screenX, screenY,
    0,
    spriteScale, spriteScale,
    texture:getWidth() / 2, texture:getHeight() / 2
  )
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
  
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


