local Constants = require('src.constants')
local Camera = require('src.camera')
local Player = require('src.player')
local Mode7 = require('src.mode7')
local Enemy = require('src.enemy')
local Projectile = require('src.projectile')

local camera
local player
local mode7
local enemies = {}
local projectiles = {}  -- Add projectiles table
local gameFont

function love.load()
  -- Load font for game over screen
  gameFont = love.graphics.newFont(32)
  
  -- Initialize game objects
  initializeGame()
end

function initializeGame()
  -- Set up window with vsync enabled
  love.window.setMode(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT, {
    resizable = false,
    vsync = true,           -- Ensure vsync is enabled
    minwidth = 400,
    minheight = 300
  })
  
  -- Initialize player first
  player = Player:new()
  player:reset()  -- Explicitly call reset
  
  -- Initialize camera to follow player
  camera = Camera:new()
  camera:reset()  -- Add explicit camera reset
  
  -- Make both globally accessible if needed
  _G.player = player
  _G.camera = camera
  
  -- Initialize other objects
  mode7 = Mode7:new()
  mode7:load()
  
  -- Reset enemies array
  enemies = {}
  projectiles = {}
  
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
  if player.isDead and player.deathTimer <= 0 then
    -- Only handle restart input when death animation is complete
    if love.keyboard.isDown('r') then
      initializeGame()
      return
    end
    return
  end
  
  player:update(dt)
  camera:update(dt, player)
  
  -- Only update game objects if player is alive
  if not player.isDead then
    -- Update enemies
    for i = #enemies, 1, -1 do
      local enemy = enemies[i]
      enemy:update(dt)
      
      -- Check collisions with projectiles
      for j = #projectiles, 1, -1 do
        local projectile = projectiles[j]
        if projectile:checkCollision(enemy, camera) then
          table.remove(projectiles, j)
          if enemy:hit(25) then
            table.remove(enemies, i)
            break
          end
        end
      end
    end
    
    -- Update projectiles
    for i = #projectiles, 1, -1 do
      local projectile = projectiles[i]
      if projectile:update(dt) then
        table.remove(projectiles, i)
      end
    end
  end
end

function love.draw()
  -- Clear screen
  love.graphics.clear(0.5, 0.7, 1.0)
  
  -- Render Mode 7 ground with enemies and projectiles
  mode7:render(camera, enemies, projectiles)
  
  -- Draw HUD
  love.graphics.setFont(love.graphics.getFont())  -- Reset to default font before HUD
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  love.graphics.print(string.format("Camera: X: %.1f Y: %.1f A: %.1f°", 
    camera.x, camera.y, math.deg(camera.angle)), 10, 30)
  love.graphics.print("Projectiles: " .. #projectiles, 10, 50)
  
  -- Draw health bar
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle('fill', 10, 70, (player.health / player.maxHealth) * 200, 20)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('line', 10, 70, 200, 20)
  love.graphics.print("Health: " .. math.floor(player.health), 10, 95)
  
  -- Flash screen red when taking damage
  if player.invulnerableTimer > 0 then
    love.graphics.setColor(1, 0, 0, player.invulnerableTimer / player.invulnerableTime * 0.3)
    love.graphics.rectangle('fill', 0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
  end
  
  -- Draw game over screen
  if player.isDead then
    love.graphics.setFont(gameFont)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
    
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("GAME OVER", 0, Constants.SCREEN_HEIGHT * 0.4, 
      Constants.SCREEN_WIDTH, "center")
    
    if player.deathTimer <= 0 then
      love.graphics.setColor(1, 1, 1)
      love.graphics.printf("Press R to Restart", 0, Constants.SCREEN_HEIGHT * 0.6, 
        Constants.SCREEN_WIDTH, "center")
    end
    
    -- Reset to default font
    love.graphics.setFont(love.graphics.getFont())
  end
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then  -- Left click
    -- Get normalized mouse coordinates (-1 to 1, with center being 0,0)
    local mouseX = -(x / love.graphics.getWidth() * 2 - 1) * 0.75  -- Added negative sign to fix inversion
    
    -- Get base direction and right vectors
    local dirVector = camera:getDirectionVector()
    local rightVector = {
      x = -dirVector.y,  -- Perpendicular to direction vector
      y = dirVector.x
    }
    
    -- Calculate final direction by adding mouse offset
    local finalDirX = dirVector.x + (rightVector.x * mouseX)
    local finalDirY = dirVector.y + (rightVector.y * mouseX)
    
    -- Normalize the final direction
    local length = math.sqrt(finalDirX * finalDirX + finalDirY * finalDirY)
    finalDirX = finalDirX / length
    finalDirY = finalDirY / length
    
    -- Calculate spawn position and angle
    local spawnDistance = 40
    local proj = Projectile:new():init(
      camera.x + finalDirX * spawnDistance,
      camera.y + finalDirY * spawnDistance,
      math.atan2(finalDirX, finalDirY),
      camera.z - 5
    )
    table.insert(projectiles, proj)
  end
end










