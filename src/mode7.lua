local Constants = require('src.constants')

local Mode7 = {
  texture = nil,
  shader = nil,
  enemyTexture = nil,
  projectileTexture = nil,
  fogColor = {0.5, 0.7, 1.0}
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
  
  -- Load enemy sprite with transparency enabled
  self.enemyTexture = love.graphics.newImage('assets/images/enemy.png')
  self.enemyTexture:setFilter('linear', 'linear')
  
  -- Add debug print to verify projectile texture loading
  print("Loading projectile texture...")
  self.projectileTexture = love.graphics.newImage('assets/images/projectile.png')
  self.projectileTexture:setFilter('linear', 'linear')
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  self.shader:send('maxDistance', Constants.DRAW_DISTANCE)
  self.shader:send('fogColor', self.fogColor)
  
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
end

function Mode7:render(camera, enemies, projectiles)
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
  
  -- Enable alpha blending for sprites
  love.graphics.setBlendMode('alpha')
  
  -- Draw enemies
  if enemies then
    for _, enemy in ipairs(enemies) do
      self:drawSprite(enemy, camera, {
        texture = self.enemyTexture,
        scale = 6.0,
        useAngleScaling = true
      })
    end
  end
  
  -- Draw projectiles
  if projectiles then
    for _, projectile in ipairs(projectiles) do
      self:drawSprite(projectile, camera, {
        texture = self.projectileTexture,
        scale = 2.0,
        useAngleScaling = false
      })
    end
  end
  
  -- Reset blend mode
  love.graphics.setBlendMode('alpha', 'alphamultiply')
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

