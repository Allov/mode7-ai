local Constants = require('src.constants')

local Mode7 = {
  texture = nil,
  shader = nil
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
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  
  -- Send texture dimensions
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
end

function Mode7:render(camera)
  -- Update shader uniforms
  self.shader:send('cameraPos', {camera.x, camera.y})
  self.shader:send('cameraAngle', camera.angle)
  
  -- Draw with shader
  love.graphics.setShader(self.shader)
  love.graphics.setColor(1, 1, 1, 1)
  
  love.graphics.draw(
    self.texture,
    0, 0,
    0,
    Constants.SCREEN_WIDTH / self.texture:getWidth(),
    Constants.SCREEN_HEIGHT / self.texture:getHeight()
  )
  
  love.graphics.setShader()
end

return Mode7




