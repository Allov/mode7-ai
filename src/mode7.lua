local Constants = require('src.constants')

local Mode7 = {
  texture = nil,
  shader = nil,
  enemyTexture = nil,
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
  self.enemyTexture:setFilter('linear', 'linear')  -- Optional: for smoother scaling
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  self.shader:send('maxDistance', Constants.DRAW_DISTANCE)
  self.shader:send('fogColor', self.fogColor)
  
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
end

function Mode7:render(camera, enemies)
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
      self:drawSprite(enemy, camera)
    end
  end
  
  -- Reset blend mode
  love.graphics.setBlendMode('alpha', 'alphamultiply')
end

function Mode7:drawSprite(enemy, camera)
  -- Adjust camera offset for X axis
  local dx = enemy.x - camera.x
  local dy = enemy.y - camera.y
  
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
  
  -- Match shader's perspective transformation exactly
  local screenX = Constants.SCREEN_WIDTH/2 + 
                  (rx * Constants.SCREEN_HEIGHT * 0.5) / ry
  
  -- Calculate ground position using same perspective
  local groundY = Constants.HORIZON_LINE + 
                  (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                  (Constants.CAMERA_HEIGHT / ry)
  
  local screenY = groundY
  -- Increased base scale factor from 2.0 to 6.0 for larger sprites
  local spriteScale = (Constants.CAMERA_HEIGHT / ry) * 6.0
  
  -- Apply fog
  local distance = math.sqrt(rx * rx + ry * ry)
  local fogFactor = math.min(distance / Constants.DRAW_DISTANCE, 1)
  love.graphics.setColor(1, 1, 1, 1 - fogFactor * 0.8)
  
  -- Fix sprite rotation to match camera space
  local spriteAngle = enemy.angle - camera.angle
  
  love.graphics.draw(
    self.enemyTexture,
    screenX,
    screenY,
    spriteAngle,
    spriteScale,
    spriteScale,
    self.enemyTexture:getWidth()/2,
    self.enemyTexture:getHeight()
  )
end

return Mode7































