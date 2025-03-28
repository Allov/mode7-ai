local Constants = require('src.constants')
local Camera = require('src.camera')
local Mode7 = require('src.mode7')

local camera
local mode7

function love.load()
  -- Set up window
  love.window.setMode(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT, {
    resizable = false,
    vsync = true,
    minwidth = 400,
    minheight = 300
  })
  
  -- Initialize objects
  camera = Camera:new()
  mode7 = Mode7:new()
  mode7:load()
  
  -- Debug info
  love.graphics.setNewFont(12)
end

function love.update(dt)
  camera:update(dt)
end

function love.draw()
  -- Clear screen
  love.graphics.clear(0.5, 0.7, 1.0)
  
  -- Render Mode 7 ground
  mode7:render(camera)
  
  -- Debug info
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  love.graphics.print("Camera: " .. string.format("X: %.1f Y: %.1f A: %.1f°", 
    camera.x, camera.y, math.deg(camera.angle)), 10, 30)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end