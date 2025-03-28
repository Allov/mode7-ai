local Constants = require('src.constants')
local Camera = require('src.camera')
local Mode7 = require('src.mode7')
local Enemy = require('src.enemy')
local Projectile = require('src.projectile')

local camera
local mode7
local enemies = {}
local projectiles = {}  -- Add projectiles table

function love.load()
  -- Set up window with vsync enabled
  love.window.setMode(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT, {
    resizable = false,
    vsync = true,           -- Ensure vsync is enabled
    minwidth = 400,
    minheight = 300
  })
  
  -- Initialize objects
  camera = Camera:new()
  mode7 = Mode7:new()
  mode7:load()
  
  -- Create some enemies
  enemies = {}
  projectiles = {}  -- Initialize projectiles table
  
  -- Add standing enemies in a circle formation
  local radius = 300
  for i = 1, 8 do
    local angle = (i - 1) * (2 * math.pi / 8)
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    local enemy = Enemy:new():init(x, y, false)  -- false = standing still
    enemy.angle = angle + math.pi  -- Face outward
    table.insert(enemies, enemy)
  end
  
  -- Add some moving enemies
  for i = 1, 3 do
    local enemy = Enemy:new():init(
      math.random(-500, 500),
      math.random(-500, 500),
      true  -- true = moving
    )
    table.insert(enemies, enemy)
  end
  
  -- Enable texture filtering
  love.graphics.setDefaultFilter('linear', 'linear')
end

function love.update(dt)
  camera:update(dt)
  
  -- Update enemies
  for _, enemy in ipairs(enemies) do
    enemy:update(dt)
  end
  
  -- Update projectiles
  for i = #projectiles, 1, -1 do
    local projectile = projectiles[i]
    if projectile:update(dt) then
      -- Remove projectile if it's expired
      table.remove(projectiles, i)
    end
  end
end

function love.draw()
  -- Clear screen
  love.graphics.clear(0.5, 0.7, 1.0)
  
  -- Render Mode 7 ground with enemies and projectiles
  mode7:render(camera, enemies, projectiles)
  
  -- Debug info
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  love.graphics.print(string.format("Camera: X: %.1f Y: %.1f A: %.1f°", 
    camera.x, camera.y, math.deg(camera.angle)), 10, 30)
  love.graphics.print("Projectiles: " .. #projectiles, 10, 50)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then  -- Left click
    -- Create new projectile at camera position, adjusted for height
    local proj = Projectile:new():init(
      camera.x,
      camera.y,
      camera.angle,
      camera.z  -- Pass camera height to init
    )
    table.insert(projectiles, proj)
  end
end







