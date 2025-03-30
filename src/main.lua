local Constants = require('src.constants')
local Player = require('src.player')
local Camera = require('src.camera')
local Mode7 = require('src.mode7')
local Rune = require('src.rune')
local Enemy = require('src.enemy')
local Projectile = require('src.projectile')
local ExperienceOrb = require('src.experienceorb')
local Chest = require('src.chest')
local PowerUp = require('src.powerup')
local GameData = require('src.gamedata')
local Boss = require('src.boss')
local Console = require('src.console')
local MobSpawner = require('src.mobspawner')

-- Declare all global variables at the top
local camera
local player
local mode7
local enemies = {}  -- Initialize empty table here
local projectiles = {}  -- Initialize empty table here
local experienceOrbs = {}
local chests = {}  -- Add chests to global variables
local powerUps = {}
local runes = {}
_G.runes = runes  -- Set global reference once
local console
local mobSpawner

-- Add to the global declarations section
_G.Rune = Rune  -- Make Rune class available to console

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
    
    -- Define spawn parameters
    local spawnDistance = 300  -- Distance from player
    local minEnemyDistance = 200  -- Minimum distance between enemies
    
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
        -- Debug print to verify function is being called and returning valid positions
        print(string.format("Found valid chest position at X:%.1f Y:%.1f", x, y))
        return x, y
      end
    end
  end
  
  print("Failed to find valid chest position") -- Debug print
  return nil, nil
end

function spawnChest()
  local x, y = findValidChestPosition()
  if x and y then
    local chest = Chest:new():init(x, y)
    table.insert(chests, chest)
    print(string.format("Spawned chest at X:%.1f Y:%.1f", x, y)) -- Debug print
  end
end

-- Modify the player's levelUp function to ensure chest spawning
function Player:levelUp()
  self.level = self.level + 1
  self.experience = self.experience - self.experienceToNextLevel
  self.experienceToNextLevel = math.floor(self.experienceToNextLevel * 1.5)
  
  -- Level up benefits
  self.maxHealth = self.maxHealth + 10
  self.health = self.maxHealth
  
  -- Debug print before spawning chest
  print("Level up! Attempting to spawn chest...")
  
  -- Spawn a chest to celebrate level up
  spawnChest()
  
  -- Debug print chest count
  print("Current chest count: " .. #chests)
  
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
  
  -- Clear arrays but maintain the same table reference
  runes = {}  -- Clear local table
  _G.runes = runes  -- Update global reference
  
  -- Make Rune class globally accessible
  _G.Rune = require('src.rune')
  
  -- Spawn random runes
  spawnRandomRunes(8)
  
  -- Enable texture filtering
  love.graphics.setDefaultFilter('nearest', 'nearest')
  
  -- Initialize mobSpawner after player and enemies table
  mobSpawner = MobSpawner:new():init(enemies, player)
  
  -- Initialize console
  console = Console:new()
  console.runes = runes  -- Give console access to the local runes table

  -- Initialize pause state
  _G.isPaused = false

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
    mobSpawner:update(dt)
    
    -- Update enemies
    for i = #enemies, 1, -1 do
      local enemy = enemies[i]
      enemy:update(dt)
      
      -- Check collisions with projectiles
      for j = #projectiles, 1, -1 do
        local projectile = projectiles[j]
        if projectile:checkCollision(enemy, camera) then
          table.remove(projectiles, j)
          -- If enemy died, spawn experience orb
          if enemy.shouldDropExp then
            local expValue = enemy.isElite and (enemy.experienceValue * 2) or enemy.experienceValue
            local expOrb = ExperienceOrb:new():init(enemy.x, enemy.y, expValue)
            table.insert(experienceOrbs, expOrb)
            print("Spawned exp orb worth: " .. expValue) -- Debug print
            
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
        print("Experience orb collected") -- Debug print
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

  -- Add mouse shooting handling
  if love.mouse.isDown(1) then  -- Left click
    if player.shootTimer <= 0 then  -- Use player's shoot timer
      -- Get normalized mouse coordinates (-1 to 1, with center being 0,0)
      local mouseX = -(love.mouse.getX() / love.graphics.getWidth() * 2 - 1) * 0.75
      
      -- Get base direction and right vectors
      local dirVector = camera:getDirectionVector()
      local rightVector = {
        x = -dirVector.y,  -- Perpendicular to direction vector
        y = dirVector.x
      }
      
      -- Calculate final direction
      local finalDirX = dirVector.x + (rightVector.x * mouseX)
      local finalDirY = dirVector.y + (rightVector.y * mouseX)
      
      spawnProjectile(finalDirX, finalDirY)
      player.shootTimer = player.shootCooldown  -- Use player's cooldown
    end
  end
  
  -- Remove the separate mouseShootTimer update since we're using player's timer
end

function drawCompass(player, runes)
  -- Position compass bar at top of screen
  local barY = 30
  local barHeight = 20  -- Reduced from 30
  local barWidth = Constants.SCREEN_WIDTH * 0.5  -- Reduced from 0.8 to 0.5 (50% of screen width)
  local barX = (Constants.SCREEN_WIDTH - barWidth) / 2
  
  -- Draw compass bar background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.rectangle('line', barX, barY, barWidth, barHeight)
  
  -- Draw cardinal points
  love.graphics.setColor(1, 1, 1, 0.8)
  local dirVector = camera:getDirectionVector()
  local playerAngle = math.atan2(dirVector.x, dirVector.y)
  
  -- Calculate positions for cardinal points
  local cardinalPoints = {
    {text = "N", angle = 0},
    {text = "E", angle = math.pi/2},
    {text = "S", angle = math.pi},
    {text = "W", angle = -math.pi/2}
  }
  
  for _, point in ipairs(cardinalPoints) do
    local relativeAngle = point.angle - playerAngle
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    local x = barX + barWidth/2 + (relativeAngle / math.pi) * (barWidth/2)
    if x >= barX and x <= barX + barWidth then
      love.graphics.print(point.text, x - 5, barY - 15)  -- Adjusted Y position
    end
  end
  
  -- Draw rune markers
  for _, rune in ipairs(runes) do
    local dx = rune.x - player.x
    local dy = rune.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dx, dy)
    
    local relativeAngle = angle - playerAngle
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    local x = barX + barWidth/2 + (relativeAngle / math.pi) * (barWidth/2)
    
    if x >= barX and x <= barX + barWidth then
      local runeData = Rune.TYPES[rune.type]
      if runeData then
        love.graphics.setColor(runeData.color[1], runeData.color[2], runeData.color[3], 1)
        love.graphics.circle('fill', x, barY + barHeight/2, 4)  -- Reduced circle size from 6 to 4
        
        local distText = string.format("%.0fm", distance)
        love.graphics.print(distText, x - 15, barY + barHeight + 2)  -- Adjusted position
      end
    end
  end
  
  -- Draw player direction indicator (triangle at center)
  love.graphics.setColor(1, 1, 1, 1)
  local triangleSize = 8  -- Reduced from 10
  local centerX = barX + barWidth/2
  love.graphics.polygon('fill',
    centerX, barY - 4,  -- Adjusted Y position
    centerX - triangleSize/2, barY + 4,
    centerX + triangleSize/2, barY + 4
  )
end

function love.draw()
  -- Clear screen with pure blue
  love.graphics.clear(0, 0, 1)
  
  -- Render Mode 7 ground with all game objects
  mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runes)
  
  -- Draw HUD with hudFont
  love.graphics.setFont(hudFont)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  
  -- Get cardinal direction based on camera's direction vector
  local dirVector = camera:getDirectionVector()  -- Using colon : for method call
  local displayAngle = math.atan2(dirVector.x, dirVector.y)
  local degrees = math.deg(displayAngle)
  if degrees < 0 then degrees = degrees + 360 end
  
  local direction = ""
  if degrees >= 337.5 or degrees < 22.5 then
    direction = "N"
  elseif degrees < 67.5 then
    direction = "NE"
  elseif degrees < 112.5 then
    direction = "E"
  elseif degrees < 157.5 then
    direction = "SE"
  elseif degrees < 202.5 then
    direction = "S"
  elseif degrees < 247.5 then
    direction = "SW"
  elseif degrees < 292.5 then
    direction = "W"
  elseif degrees < 337.5 then
    direction = "NW"
  end
  
  -- Display position, angle, and cardinal direction
  love.graphics.print(string.format("Position: X: %.1f Y: %.1f", player.x, player.y), 10, 30)
  love.graphics.print(string.format("Facing: %s (%.1f°)", direction, degrees), 10, 50)
  love.graphics.print("Projectiles: " .. #projectiles, 10, 70)
  love.graphics.print("Enemies: " .. #enemies, 10, 90)
  love.graphics.print(string.format("Spawn Rate: %.1fs", mobSpawner.spawnInterval), 10, 110)
  
  -- Draw health bar
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle('fill', 10, 130, (player.health / player.maxHealth) * 200, 20)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('line', 10, 130, 200, 20)
  love.graphics.print("Health: " .. math.floor(player.health), 10, 155)
  
  -- Draw experience bar
  love.graphics.setColor(0, 1, 1, 0.8)  -- Cyan color for XP
  love.graphics.rectangle('fill', 10, 180, 
    (player.experience / player.experienceToNextLevel) * 200, 20)
  love.graphics.setColor(0, 0.7, 0.7, 1)  -- Darker cyan for border
  love.graphics.rectangle('line', 10, 180, 200, 20)
  
  -- Draw level and XP text
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Level " .. player.level, 10, 205)
  love.graphics.print(string.format("XP: %d/%d", 
    player.experience, player.experienceToNextLevel), 10, 225)
    
  -- Draw active power-ups with hudFont
  local powerUpY = 250
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

  -- Draw compass after other HUD elements
  drawCompass(player, runes)

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

function spawnProjectile(dirX, dirY)
  -- Normalize the direction
  local length = math.sqrt(dirX * dirX + dirY * dirY)
  local finalDirX = dirX / length
  local finalDirY = dirY / length
  
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

-- Remove or comment out the old mousepressed function since we're handling it in update now
--[[
function love.mousepressed(x, y, button)
  -- Old click handling code...
end
--]]


-- Make these global for console access
_G.spawnEnemy = function() mobSpawner:spawnEnemy() end
_G.spawnBoss = function() mobSpawner:spawnBoss() end
_G.spawnChest = spawnChest
_G.findValidSpawnPosition = findValidSpawnPosition
_G.initializeGame = initializeGame
_G.enemies = enemies
_G.projectiles = projectiles
_G.Enemy = Enemy  -- Add Enemy class to globals

function spawnRandomRunes(count)
  -- Get all available rune types from GameData
  local availableRuneTypes = {}
  for runeType, _ in pairs(GameData.RUNE_TYPES) do
    table.insert(availableRuneTypes, runeType)
  end
  
  -- First, spawn one rune close to the player (within 500 units)
  local nearDistance = {
    min = 200,  -- Not too close
    max = 500   -- Within reasonable reach
  }
  
  -- Spawn the near rune
  local nearAngle = math.random() * math.pi * 2
  local nearDist = nearDistance.min + math.random() * (nearDistance.max - nearDistance.min)
  local nearX = math.cos(nearAngle) * nearDist
  local nearY = math.sin(nearAngle) * nearDist
  
  -- Choose random rune type for near rune
  local nearRuneType = availableRuneTypes[math.random(#availableRuneTypes)]
  local nearRune = _G.Rune:new():init(nearX, nearY, nearRuneType)
  table.insert(_G.runes, nearRune)
  
  print(string.format("Spawned starting %s rune at X:%.1f Y:%.1f (Distance: %.1f)", 
    nearRuneType, nearX, nearY, nearDist))
  
  -- Parameters for remaining distant runes
  local minDistance = 15000
  local maxDistance = 20000
  local minAngleDiff = math.pi/2
  
  local usedAngles = { nearAngle }  -- Include the near rune's angle
  
  -- Spawn remaining runes at distance (count - 1 since we already spawned one)
  for i = 1, count - 1 do
    local attempts = 20
    local validPosition = false
    
    while attempts > 0 and not validPosition do
      local angle = math.random() * math.pi * 2
      
      local validAngle = true
      for _, usedAngle in ipairs(usedAngles) do
        local angleDiff = math.abs(angle - usedAngle)
        angleDiff = math.min(angleDiff, math.pi * 2 - angleDiff)
        if angleDiff < minAngleDiff then
          validAngle = false
          break
        end
      end
      
      if validAngle then
        local distance = minDistance + math.random() * (maxDistance - minDistance)
        local x = math.cos(angle) * distance
        local y = math.sin(angle) * distance
        
        local runeType = availableRuneTypes[math.random(#availableRuneTypes)]
        local rune = _G.Rune:new():init(x, y, runeType)
        table.insert(_G.runes, rune)
        table.insert(usedAngles, angle)
        validPosition = true
        
        print(string.format("Spawned distant %s rune at X:%.1f Y:%.1f (Distance: %.1f)", 
          runeType, x, y, distance))
      end
      
      attempts = attempts - 1
    end
  end
end
