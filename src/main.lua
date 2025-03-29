local Constants = require('src.constants')
local Camera = require('src.camera')
local Player = require('src.player')
local Mode7 = require('src.mode7')
local Enemy = require('src.enemy')
local Projectile = require('src.projectile')
local ExperienceOrb = require('src.experienceorb')
local Chest = require('src.chest')
local PowerUp = require('src.powerup')
local GameData = require('src.gamedata')
local Boss = require('src.boss')
local Rune = require('src.rune')
local Console = require('src.console')

-- Declare all global variables at the top
local camera
local player
local mode7
local enemies = {}  -- Initialize empty table here
local projectiles = {}  -- Initialize empty table here
local experienceOrbs = {}
local gameFont
local chests = {}  -- Add chests to global variables
local powerUps = {}
local runes = {}
local console

-- Add spawn control variables
local spawnTimer = 0
local spawnInterval = 3.0  -- Start with 3 seconds between spawns
local minSpawnInterval = 0.5  -- Fastest spawn rate
local spawnIntervalDecay = 0.95  -- Reduce interval by 5% each spawn
local spawnDistance = 500  -- How far from player to spawn enemies
local minEnemyDistance = 150  -- Minimum distance between enemies

function getDistanceToNearestEnemy(x, y)
  if #enemies == 0 then return math.huge end  -- Return huge distance if no enemies
  
  local minDist = math.huge
  for _, enemy in ipairs(enemies) do
    local dx = enemy.x - x
    local dy = enemy.y - y
    local dist = math.sqrt(dx * dx + dy * dy)
    minDist = math.min(minDist, dist)
  end
  return minDist
end

function findValidSpawnPosition()
  -- Try up to 10 different positions
  for _ = 1, 10 do
    -- Generate random angle around player
    local angle = math.random() * math.pi * 2
    
    -- Calculate spawn position
    local spawnX = player.x + math.cos(angle) * spawnDistance
    local spawnY = player.y + math.sin(angle) * spawnDistance
    
    -- Check distance to nearest enemy
    if getDistanceToNearestEnemy(spawnX, spawnY) >= minEnemyDistance then
      return spawnX, spawnY
    end
  end
  
  -- If no valid position found after 10 tries, return nil
  return nil, nil
end

function findValidChestPosition()
  local attempts = 10
  local minDistance = 200  -- Minimum distance from player
  local maxDistance = 400  -- Maximum distance from player
  
  for _ = 1, attempts do
    -- Generate random angle and distance
    local angle = math.random() * math.pi * 2
    local distance = minDistance + math.random() * (maxDistance - minDistance)
    
    -- Calculate position
    local x = player.x + math.cos(angle) * distance
    local y = player.y + math.sin(angle) * distance
    
    -- Check if position is valid (not too close to enemies or other chests)
    if getDistanceToNearestEnemy(x, y) >= 150 then
      -- Check distance to other chests
      local tooClose = false
      for _, chest in ipairs(chests) do
        local dx = chest.x - x
        local dy = chest.y - y
        if math.sqrt(dx * dx + dy * dy) < 200 then
          tooClose = true
          break
        end
      end
      
      if not tooClose then
        return x, y
      end
    end
  end
  
  return nil, nil
end

function spawnChest()
  local x, y = findValidChestPosition()
  if x and y then
    local chest = Chest:new():init(x, y)
    table.insert(chests, chest)
  end
end

-- Modify the player's levelUp function to spawn a chest
function Player:levelUp()
  self.level = self.level + 1
  self.experience = self.experience - self.experienceToNextLevel
  self.experienceToNextLevel = math.floor(self.experienceToNextLevel * 1.5)
  
  -- Level up benefits
  self.maxHealth = self.maxHealth + 10
  self.health = self.maxHealth
  
  -- Spawn a chest to celebrate level up
  spawnChest()
  
  -- Spawn boss every 5 levels
  if self.level % 5 == 0 then
    spawnBoss()
  end
end

function love.load()
  -- Load different fonts for different UI elements
  hudFont = love.graphics.newFont(16)  -- Smaller font for HUD
  notificationFont = love.graphics.newFont(32)  -- Larger font for center notifications
  
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
  
  -- Clear arrays
  enemies = {}
  projectiles = {}
  experienceOrbs = {}
  chests = {}  -- Clear chests array
  powerUps = {}
  runes = {}
  
  -- Enable texture filtering
  love.graphics.setDefaultFilter('linear', 'linear')
  
  -- Reset spawn control
  spawnTimer = 0
  spawnInterval = 3.0
  
  -- Initialize console
  console = Console:new()

  -- Initialize pause state
  _G.isPaused = false
end

function spawnEnemy()
  -- Find valid spawn position
  local spawnX, spawnY = findValidSpawnPosition()
  
  -- Only spawn if valid position found
  if spawnX and spawnY then
    -- 10% chance to spawn an elite enemy
    local isElite = math.random() < 0.10
    
    -- Create and add new enemy
    local enemy = Enemy:new():init(spawnX, spawnY, isElite)
    table.insert(enemies, enemy)
    
    -- Reduce spawn interval, but not below minimum
    spawnInterval = math.max(minSpawnInterval, spawnInterval * spawnIntervalDecay)
  end
end

function spawnBoss()
  -- Find valid spawn position (similar to enemy spawn)
  local angle = math.random() * math.pi * 2
  local spawnDistance = 800  -- Increased from 600 to be more visible
  
  local spawnX = player.x + math.cos(angle) * spawnDistance
  local spawnY = player.y + math.sin(angle) * spawnDistance
  
  -- Create and add new boss
  local boss = Boss:new():init(spawnX, spawnY)
  table.insert(enemies, boss)  -- Add to enemies table
  
  -- Debug print to confirm spawn
  print(string.format("Boss spawned at: X=%.1f, Y=%.1f", spawnX, spawnY))
  
  -- Show announcement
  bossSpawnTimer = 3  -- Show announcement for 3 seconds
end

function love.update(dt)
  -- Return early if game is paused (but not if player is dead)
  if _G.isPaused and not player.isDead then
    return
  end

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
    -- Update spawn timer
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
      spawnTimer = 0
      spawnEnemy()
    end
    
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
            -- Check if should drop experience
            if enemy.shouldDropExp then
              local expOrb = ExperienceOrb:new():init(enemy.x, enemy.y, enemy.experienceValue)
              table.insert(experienceOrbs, expOrb)
            end
            
            -- Handle rune drop from boss
            if enemy.shouldDropRune then
              local rune = Rune:new():init(
                enemy.shouldDropRune.x,
                enemy.shouldDropRune.y,
                enemy.shouldDropRune.type
              )
              table.insert(runes, rune)
            end
            
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
    
    -- Update experience orbs
    for i = #experienceOrbs, 1, -1 do
      if experienceOrbs[i]:update(dt) then
        table.remove(experienceOrbs, i)
      end
    end
    
    -- Update chests
    for i = #chests, 1, -1 do
      local chest = chests[i]
      if chest:update(dt) then
        if chest.spawnPowerUp then
          -- Spawn power-up
          local powerUp = PowerUp:new():init(
            chest.spawnPowerUp.x,
            chest.spawnPowerUp.y,
            chest.spawnPowerUp.type
          )
          table.insert(powerUps, powerUp)
        elseif chest.spawnExperienceOrbs then
          -- Add all spawned experience orbs
          for _, orb in ipairs(chest.spawnExperienceOrbs) do
            table.insert(experienceOrbs, orb)
          end
        end
        table.remove(chests, i)
      end
    end

    -- Update power-ups
    for i = #powerUps, 1, -1 do
      if powerUps[i]:update(dt) then
        table.remove(powerUps, i)
      end
    end

    -- Update runes
    for i = #runes, 1, -1 do
      if runes[i]:update(dt) then
        table.remove(runes, i)
      end
    end
  end

  if bossSpawnTimer then
    bossSpawnTimer = bossSpawnTimer - dt
    if bossSpawnTimer <= 0 then
      bossSpawnTimer = nil
    end
  end
end

function love.draw()
  -- Clear screen
  love.graphics.clear(0.5, 0.7, 1.0)
  
  -- Render Mode 7 ground with all game objects
  mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runes)
  
  -- Draw HUD with hudFont
  love.graphics.setFont(hudFont)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  love.graphics.print(string.format("Camera: X: %.1f Y: %.1f A: %.1f°", 
    camera.x, camera.y, math.deg(camera.angle)), 10, 30)
  love.graphics.print("Projectiles: " .. #projectiles, 10, 50)
  love.graphics.print("Enemies: " .. #enemies, 10, 70)
  love.graphics.print(string.format("Spawn Rate: %.1fs", spawnInterval), 10, 90)
  
  -- Draw health bar
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle('fill', 10, 110, (player.health / player.maxHealth) * 200, 20)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('line', 10, 110, 200, 20)
  love.graphics.print("Health: " .. math.floor(player.health), 10, 135)
  
  -- Draw experience bar
  love.graphics.setColor(0, 1, 1, 0.8)  -- Cyan color for XP
  love.graphics.rectangle('fill', 10, 160, 
    (player.experience / player.experienceToNextLevel) * 200, 20)
  love.graphics.setColor(0, 0.7, 0.7, 1)  -- Darker cyan for border
  love.graphics.rectangle('line', 10, 160, 200, 20)
  
  -- Draw level and XP text
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Level " .. player.level, 10, 185)
  love.graphics.print(string.format("XP: %d/%d", 
    player.experience, player.experienceToNextLevel), 10, 205)
    
  -- Draw active power-ups with hudFont
  local powerUpY = 230
  love.graphics.print("Active Power-ups:", 10, powerUpY)
  powerUpY = powerUpY + 25
  
  for _, powerUp in ipairs(player.activePowerUps) do
    local powerUpKey = powerUp.type:upper()
    local powerUpData = GameData.POWERUP_TYPES[powerUpKey]
    
    if powerUpData then
      love.graphics.setColor(powerUpData.color[1], powerUpData.color[2], powerUpData.color[3], 0.3)
      love.graphics.rectangle('fill', 10, powerUpY, 200, 20)
      
      love.graphics.setColor(1, 1, 1)
      local text = string.format("%s (%.1fs)", powerUpData.description, powerUp.timeLeft)
      love.graphics.print(text, 15, powerUpY + 2)
      
      love.graphics.setColor(powerUpData.color[1], powerUpData.color[2], powerUpData.color[3], 0.8)
      local barWidth = (powerUp.timeLeft / powerUp.duration) * 190
      love.graphics.rectangle('fill', 15, powerUpY + 15, barWidth, 3)
      
      powerUpY = powerUpY + 25
    end
  end
  
  -- Center notifications with notificationFont
  love.graphics.setFont(notificationFont)
  
  -- Draw chest interaction prompt
  for _, chest in ipairs(chests) do
    if not chest.isOpen then
      local dx = player.x - chest.x
      local dy = player.y - chest.y
      local distance = math.sqrt(dx * dx + dy * dy)
      
      if distance < chest.interactRadius then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press E to open", 
          Constants.SCREEN_WIDTH/2 - 100,
          Constants.SCREEN_HEIGHT - 100,
          200, "center")
      end
    end
  end

  -- Draw boss spawn announcement
  if bossSpawnTimer and bossSpawnTimer > 0 then
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("BOSS HAS APPEARED!", 
      0, Constants.SCREEN_HEIGHT/2 - 50, 
      Constants.SCREEN_WIDTH, "center")
  end

  -- Draw game over screen
  if player.isDead then
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
  end

  -- Draw active runes in top right
  love.graphics.setFont(hudFont)
  local runeX = Constants.SCREEN_WIDTH - 210  -- Start 210 pixels from right edge
  local runeY = 10  -- Start 10 pixels from top
  local runeWidth = 200  -- Width of rune display area
  
  love.graphics.print("Active Runes:", runeX, runeY)
  runeY = runeY + 25
  
  for _, runeType in ipairs(player.runes) do
    local runeData = Rune.TYPES[runeType]
    if runeData then
      -- Draw rune background
      love.graphics.setColor(runeData.color[1], runeData.color[2], runeData.color[3], 0.3)
      
      -- Calculate height needed for wrapped text
      local _, descriptionWrapped = hudFont:getWrap(runeData.description, runeWidth - 10)
      local textHeight = #descriptionWrapped * hudFont:getHeight()
      local totalHeight = textHeight + hudFont:getHeight() + 10  -- Name + description + padding
      
      love.graphics.rectangle('fill', runeX, runeY, runeWidth, totalHeight)
      
      -- Draw rune name and effects
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(runeData.name, runeX + 5, runeY + 2)
      
      love.graphics.setColor(runeData.color[1], runeData.color[2], runeData.color[3], 0.8)
      love.graphics.printf(runeData.description, 
        runeX + 5, 
        runeY + hudFont:getHeight() + 5, 
        runeWidth - 10, 
        "left")
      
      runeY = runeY + totalHeight + 5  -- Add small gap between runes
    end
  end

  -- Reset color and font
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(hudFont)

  -- Draw console last
  console:draw()
end

function love.keypressed(key)
  if key == '`' then
    console:toggle()
    return
  end
  
  if console:handleInput(key) then
    return
  end
  
  if key == 'escape' then
    love.event.quit()
  end
end

function love.textinput(text)
  if console:textinput(text) then
    return
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

-- Make these global for console access
_G.spawnEnemy = spawnEnemy
_G.spawnBoss = spawnBoss
_G.spawnChest = spawnChest
_G.findValidSpawnPosition = findValidSpawnPosition
_G.initializeGame = initializeGame
_G.enemies = enemies
_G.projectiles = projectiles
_G.Enemy = Enemy  -- Add Enemy class to globals
