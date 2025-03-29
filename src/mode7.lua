local Constants = require('src.constants')

local Mode7 = {
  texture = nil,
  shader = nil,
  skyTexture = nil,  -- Add sky texture
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
end

function Mode7:render(camera, enemies, projectiles)
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
      self:drawSprite(enemy, camera, {
        texture = self.enemyTexture,
        scale = 6.0,
        useAngleScaling = true
      })
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
end

function Mode7:drawSprite(entity, camera, options)
  options = options or {}
  local texture = options.texture or self.enemyTexture
  local scale = options.scale or 6.0
  local useAngleScaling = options.useAngleScaling or false
  
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
  
  -- Position sprite above ground position by half its height
  local screenY = groundY - (texture:getHeight() * spriteScale / 2)
  
  -- Apply fog
  local distance = math.sqrt(rx * rx + ry * ry)
  local fogFactor = math.min(distance / Constants.DRAW_DISTANCE, 1)
  love.graphics.setColor(1, 1, 1, 1 - fogFactor * 0.8)
  
  -- Calculate width scaling based on viewing angle if needed
  local widthScale = spriteScale
  local heightScale = spriteScale
  
  if useAngleScaling then
    local relativeAngle = math.atan2(dx, dy) - camera.angle
    local angleScale = math.abs(math.cos(relativeAngle))
    widthScale = spriteScale * (0.2 + 0.8 * angleScale)  -- Keep minimum width of 20%
  end
  
  love.graphics.draw(
    texture,
    screenX,
    screenY,
    0,  -- Keep sprite upright
    widthScale,
    heightScale,
    texture:getWidth()/2,
    texture:getHeight()/2
  )
end

return Mode7


