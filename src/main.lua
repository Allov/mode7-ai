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
local RuneSpawner = require('src.runespawner')
local OrbItem = require('src.orbitem')
local Lightning = require('src.effects.lightning')
local PlayerArms = require('src.playerarms')
local DeadTree = require('src.environment.dead_tree')
local SpookyBush = require('src.environment.spooky_bush')

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
local runeSpawner
local orbItems = {}  -- Initialize empty table for orb items on ground
_G.runes = runes  -- Set global reference once
local console
local mobSpawner
local playerArms  -- Add playerArms here
local deadTrees = {}  -- Initialize as empty table
local textureManager  -- Add texture manager variable
local spookyBushes = {}  -- Initialize as empty table

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
  -- Seed random number generator with current time
  math.randomseed(os.time())
  -- Warm up the random number generator by discarding first few values
  for i = 1, 3 do math.random() end
  
  -- Load different fonts for different UI elements
  hudFont = love.graphics.newFont(16)  -- Smaller font for HUD
  notificationFont = love.graphics.newFont(32)  -- Larger font for center notifications
  
  -- Initialize game objects
  initializeGame()
  
  -- Initialize mouse state
  _G.mouseGrabbed = true
  love.mouse.setVisible(false)
end

function initializeGame()
  -- Initialize global effects table if it doesn't exist
  _G.effects = _G.effects or {}
  
  -- Set up window in fullscreen mode
  love.window.setMode(0, 0, {
    fullscreen = true,
    vsync = true,
    resizable = false,
    minwidth = 400,
    minheight = 300
  })
  
  -- Update Constants with actual screen dimensions
  Constants.SCREEN_WIDTH = love.graphics.getWidth()
  Constants.SCREEN_HEIGHT = love.graphics.getHeight()
  
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
  
  -- Initialize playerArms right after player
  playerArms = PlayerArms:new()
  print("PlayerArms initialized:", playerArms) -- Debug print
  
  -- Initialize rune spawner
  runeSpawner = RuneSpawner:new():init(player)
  _G.runeSpawner = runeSpawner  -- Make globally accessible
  _G.runes = runeSpawner:getRunes()  -- Update global reference
  
  -- Spawn initial runes
  -- Spawn one close rune
  local nearAngle = math.random() * math.pi * 2
  local nearDist = 200 + math.random() * 300  -- Between 200 and 500 units
  local nearX = player.x + math.cos(nearAngle) * nearDist
  local nearY = player.y + math.sin(nearAngle) * nearDist
  runeSpawner:spawnRune(nil, nearX, nearY)  -- nil for random rune type
  
  -- Spawn a few distant runes
  for i = 1, 3 do
    local farAngle = math.random() * math.pi * 2
    local farDist = 15000 + math.random() * 5000  -- Between 15000 and 20000 units
    local farX = player.x + math.cos(farAngle) * farDist
    local farY = player.y + math.sin(farAngle) * farDist
    runeSpawner:spawnRune(nil, farX, farY)
  end
  
  -- Make Rune class globally accessible
  _G.Rune = require('src.rune')
  
  -- Initialize mobSpawner after player and enemies table
  mobSpawner = MobSpawner:new():init(enemies, player, experienceOrbs)  -- Add experienceOrbs parameter
  
  -- Initialize console
  console = Console:new()
  console.runes = runeSpawner:getRunes()  -- Give console access to runes table

  -- Initialize pause state
  _G.isPaused = false

  -- Initialize orb spawner
  player.orbSpawner = require('src.orbspawner'):new():init(player)
  
  -- Initialize orb item spawner
  orbItemSpawner = require('src.orbitemspawner'):new():init(player)
  _G.orbItemSpawner = orbItemSpawner
  
  -- Spawn initial orb item near player
  local orbDist = 100 + math.random() * 100  -- Between 100 and 200 units
  local orbAngle = math.random() * math.pi * 2
  local orbX = player.x + math.cos(orbAngle) * orbDist
  local orbY = player.y + math.sin(orbAngle) * orbDist
  
  -- Get random orb type and spawn the initial orb item
  local availableTypes = player.orbSpawner.orbTypes
  local randomOrbType = availableTypes[math.random(#availableTypes)]
  orbItemSpawner:spawnOrbItem(randomOrbType, orbX, orbY)

  _G.effects = {} -- Global effects table

  -- After creating mobSpawner
  _G.mobSpawner = mobSpawner

  -- Initialize dead trees with clusters
  local deadTrees = DeadTree.generateClusters(
      50,         -- Number of clusters
      8,          -- Trees per cluster
      20000       -- Map radius
  )

  -- Add some random individual trees for variety
  for i = 1, 300 do
      local angle = math.random() * math.pi * 2
      local distance = math.random() * 20000
      local x = math.cos(angle) * distance
      local y = math.sin(angle) * distance
      
      -- Check if position is valid
      local validPosition = true
      for _, tree in ipairs(deadTrees) do
          local dx = tree.x - x
          local dy = tree.y - y
          local dist = math.sqrt(dx * dx + dy * dy)
          if dist < DeadTree.minTreeSpacing then
              validPosition = false
              break
          end
      end
      
      if validPosition then
          table.insert(deadTrees, DeadTree:new():init(x, y))
      end
  end

  -- Make trees globally accessible if needed
  _G.deadTrees = deadTrees

  -- Initialize spooky bushes with clusters
  local spookyBushes = SpookyBush.generateClusters(
      70,         -- More clusters than trees
      6,          -- Bushes per cluster
      20000       -- Map radius
  )

  -- Add some random individual bushes
  for i = 1, 400 do
      local angle = math.random() * math.pi * 2
      local distance = math.random() * 20000
      local x = math.cos(angle) * distance
      local y = math.sin(angle) * distance
      
      local validPosition = true
      for _, bush in ipairs(spookyBushes) do
          local dx = bush.x - x
          local dy = bush.y - y
          local dist = math.sqrt(dx * dx + dy * dy)
          if dist < SpookyBush.minBushSpacing then
              validPosition = false
              break
          end
      end
      
      if validPosition then
          table.insert(spookyBushes, SpookyBush:new():init(x, y))
      end
  end

  -- Make bushes globally accessible
  _G.spookyBushes = spookyBushes
end

function love.update(dt)
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
  
  -- Update playerArms if it exists
  if playerArms then
    playerArms:update(dt, player)
  end
  
  -- Only update game objects if player is alive
  if not player.isDead then
    mobSpawner:update(dt)
    runeSpawner:update(dt)
    orbItemSpawner:update(dt)  -- Add this line
    
    -- Update enemies
    for i = #enemies, 1, -1 do
      local enemy = enemies[i]
      enemy:update(dt)
      
      -- Check collisions with projectiles
      for j = #projectiles, 1, -1 do
        local projectile = projectiles[j]
        if projectile:checkCollision(enemy, camera) then
          table.remove(projectiles, j)
          -- Remove the enemy removal logic from here - let death queue handle it
          break
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

    -- Update orb items
    for i = #orbItems, 1, -1 do
      if orbItems[i]:update(dt) then
        table.remove(orbItems, i)
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

  -- Update effects
  for i = #_G.effects, 1, -1 do
    local effect = _G.effects[i]
    if effect.object:update(dt) then
      table.remove(_G.effects, i)
    end
  end
end

function drawCompass(player, runeSpawner)
  -- Position compass bar at top of screen
  local barY = 30
  local barHeight = 20
  local barWidth = Constants.SCREEN_WIDTH * 0.5
  local barX = (Constants.SCREEN_WIDTH - barWidth) / 2
  
  -- Draw compass bar background with gradient
  love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
  love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)
  love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
  love.graphics.rectangle('line', barX, barY, barWidth, barHeight)
  
  -- Draw cardinal points
  love.graphics.setColor(0.7, 0.7, 0.8, 0.8)
  local directions = {"N", "E", "S", "W"}
  local angles = {0, math.pi/2, math.pi, -math.pi/2}
  local dirVector = camera:getDirectionVector()
  local playerAngle = math.atan2(dirVector.x, dirVector.y)
  
  for i, dir in ipairs(directions) do
    local relativeAngle = angles[i] - playerAngle
    -- Normalize angle to [-π, π]
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    local dirX = barX + barWidth * (0.5 + relativeAngle / (math.pi))
    if dirX >= barX and dirX <= barX + barWidth then
      love.graphics.printf(dir, dirX - 10, barY + barHeight/2 - 8, 20, "center")
    end
  end
  
  -- Draw tick marks
  for i = -6, 6 do
    local tickX = barX + barWidth * (0.5 + i/6)
    if i % 2 == 0 then
      love.graphics.setColor(0.7, 0.7, 0.8, 0.4)
      love.graphics.line(tickX, barY + 2, tickX, barY + barHeight - 2)
    end
  end
  
  -- Get runes from runeSpawner
  local runes = runeSpawner:getRunes()
  
  -- Draw rune indicators
  for _, rune in ipairs(runes) do
    local dx = rune.x - player.x
    local dy = rune.y - player.y
    local angleToRune = math.atan2(dx, dy)
    local distance = math.sqrt(dx * dx + dy * dy)
    local relativeAngle = angleToRune - playerAngle
    
    -- Normalize angle to [-π, π]
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    local runeX = barX + barWidth * (0.5 + relativeAngle / (math.pi))
    
    if runeX >= barX and runeX <= barX + barWidth then
      -- Draw distance above the compass bar with background
      love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
      love.graphics.rectangle('fill', runeX - 25, barY - 20, 50, 15, 3, 3)  -- Increased width from 40 to 50
      love.graphics.setColor(1, 0.8, 0, 0.9)
      love.graphics.printf(math.floor(distance), runeX - 25, barY - 19, 50, "center")  -- Increased width from 40 to 50
      
      -- Draw rune indicator (improved triangle)
      love.graphics.setColor(1, 0.8, 0, 0.9)
      love.graphics.polygon('fill', 
        runeX, barY,  -- Top point
        runeX - 4, barY + 6,  -- Bottom left
        runeX + 4, barY + 6   -- Bottom right
      )
      love.graphics.setColor(1, 1, 1, 0.3)
      love.graphics.polygon('line', 
        runeX, barY,  -- Top point
        runeX - 4, barY + 6,  -- Bottom left
        runeX + 4, barY + 6   -- Bottom right
      )
    end
  end
  
  -- Get GameData for orb colors
  local GameData = require('src.gamedata')
  
  -- Draw orb indicators
  for _, orbItem in ipairs(orbItems) do
    local dx = orbItem.x - player.x
    local dy = orbItem.y - player.y
    local angleToOrb = math.atan2(dx, dy)
    local distance = math.sqrt(dx * dx + dy * dy)
    local relativeAngle = angleToOrb - playerAngle
    
    -- Normalize angle to [-π, π]
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    local orbX = barX + barWidth * (0.5 + relativeAngle / (math.pi))
    
    if orbX >= barX and orbX <= barX + barWidth then
      -- Draw distance below compass with background
      love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
      love.graphics.rectangle('fill', orbX - 25, barY + barHeight + 5, 50, 15, 3, 3)  -- Increased width from 40 to 50
      
      -- Get orb color from GameData
      local orbColor = GameData.ORBS[orbItem.type] and GameData.ORBS[orbItem.type].color or {1, 1, 1}
      love.graphics.setColor(orbColor[1], orbColor[2], orbColor[3], 0.9)
      love.graphics.printf(math.floor(distance), orbX - 25, barY + barHeight + 6, 50, "center")  -- Increased width from 40 to 50
      
      -- Draw improved orb indicator
      love.graphics.circle('fill', orbX, barY + barHeight - 4, 3)
      love.graphics.setColor(1, 1, 1, 0.3)
      love.graphics.circle('line', orbX, barY + barHeight - 4, 3)
    end
  end
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

-- Helper function for drawing bars
local function drawBar(x, y, width, height, value, maxValue, colors, showText, text)
    -- Background shadow (reduced opacity)
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle('fill', x + 2, y + 2, width, height)
    
    -- Background (made darker and more opaque)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle('fill', x, y, width, height)
    
    -- Progress
    local progress = value / maxValue
    local progressWidth = width * progress
    
    -- Main bar color (flat look)
    love.graphics.setColor(colors.r1, colors.g1, colors.b1, 0.9)
    love.graphics.rectangle('fill', x, y, progressWidth, height)
    
    -- Subtle highlight at top
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle('fill', x, y, progressWidth, height/3)
    
    -- Text
    if showText then
        -- Text shadow
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.printf(text, x + 1, y + height/2 - 9, width, "center")
        
        -- Actual text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(text, x, y + height/2 - 10, width, "center")
    end
end

function love.draw()
  -- Clear screen with pure blue
  love.graphics.clear(0, 0, 1)
  
  -- Get runes directly from runeSpawner instead of global table
  local runesToRender = runeSpawner:getRunes()
  
  -- Debug print tree count periodically
  if not _G.lastTreeCount or love.timer.getTime() - _G.lastTreeCount > 1 then
    _G.lastTreeCount = love.timer.getTime()
  end
  
  -- Make sure we're using the correct trees variable
  local treesToRender = _G.deadTrees or deadTrees or {}
  local bushesToRender = _G.spookyBushes or spookyBushes or {}

  enemies = _G.enemies
  
  -- Render Mode 7 ground with all game objects
  mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runesToRender, orbItemSpawner:getOrbItems(), treesToRender, bushesToRender)
  
  -- Draw player arms if it exists
  if playerArms then
    playerArms:draw()
  end
  
  -- Draw HUD with hudFont
  love.graphics.setFont(hudFont)
  love.graphics.setColor(1, 1, 1)
  -- Remove these lines:
  -- love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
  -- love.graphics.print("Projectiles: " .. #projectiles, 10, 70)
  -- love.graphics.print("Enemies: " .. #enemies, 10, 90)
  -- love.graphics.print(string.format("Spawn Rate: %.1fs", mobSpawner.spawnInterval), 10, 110)
  
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
  
  -- Constants for bars and info box
  local barWidth = 250
  local barHeight = 25
  local barX = 10
  local healthY = Constants.SCREEN_HEIGHT - 70
  local expY = Constants.SCREEN_HEIGHT - 35
  local gapBetweenBars = expY - (healthY + barHeight)
  local totalHeight = (barHeight * 2) + gapBetweenBars
  local countSize = totalHeight

  -- Define colors
  local healthColors = {
    r1 = 0.8, g1 = 0.2, b1 = 0.2,  -- Dark red
    r2 = 1.0, g2 = 0.3, b2 = 0.3   -- Bright red
  }

  -- Draw health bar
  -- Background shadow
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle('fill', barX + 2, healthY + 2, barWidth, barHeight)
  
  -- Main background
  love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
  love.graphics.rectangle('fill', barX, healthY, barWidth, barHeight)

  -- Health bar fill
  local progress = player.health / player.maxHealth
  love.graphics.setColor(healthColors.r1, healthColors.g1, healthColors.b1, 0.9)
  love.graphics.rectangle('fill', barX, healthY, barWidth * progress, barHeight)

  -- Health text
  local healthText = string.format("%d / %d HP", math.floor(player.health), player.maxHealth)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(healthText, barX, healthY + barHeight/2 - 10, barWidth, "center")

  -- Draw experience bar
  local expColors = {
    r1 = 0.2, g1 = 0.6, b1 = 0.8,  -- Dark cyan
    r2 = 0.4, g2 = 0.8, b2 = 1.0   -- Bright cyan
  }
  local expText = string.format("Level %d  -  %d / %d XP", 
                              player.level, player.experience, player.experienceToNextLevel)
  drawBar(barX, expY, barWidth, barHeight, player.experience, player.experienceToNextLevel, 
         expColors, true, expText)

  -- Draw enemy count box (tall square)
  -- Background shadow
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle('fill', barX + barWidth + 12, healthY + 2, countSize, totalHeight)
  
  -- Main background
  love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
  love.graphics.rectangle('fill', barX + barWidth + 10, healthY, countSize, totalHeight)
  
  -- Enemy count fill
  love.graphics.setColor(healthColors.r1, healthColors.g1, healthColors.b1, 0.9)
  love.graphics.rectangle('fill', barX + barWidth + 10, healthY, countSize, totalHeight)
  
  -- Enemy count text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("MOBS", barX + barWidth + 10, healthY + totalHeight/2 - 20, countSize, "center")
  love.graphics.printf(#enemies, barX + barWidth + 10, healthY + totalHeight/2, countSize, "center")

  -- Draw FPS counter to the right of mobs counter
  -- Background shadow
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle('fill', barX + barWidth + countSize + 22, healthY + 2, countSize, totalHeight)
  
  -- Main background
  love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
  love.graphics.rectangle('fill', barX + barWidth + countSize + 20, healthY, countSize, totalHeight)
  
  -- FPS text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("FPS", barX + barWidth + countSize + 20, healthY + totalHeight/2 - 20, countSize, "center")
  love.graphics.printf(love.timer.getFPS(), barX + barWidth + countSize + 20, healthY + totalHeight/2, countSize, "center")

  -- Draw active power-ups with hudFont
  local powerUpY = 250
  local powerUpX = 10
  local powerUpWidth = 280  -- Increased from 220 to 280
  local powerUpHeight = 30
  local padding = 5
  local cornerRadius = 6

  -- Title with background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', powerUpX, powerUpY, powerUpWidth, 25, cornerRadius)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Active Power-ups", powerUpX + padding, powerUpY + 4)
  powerUpY = powerUpY + 30

  -- Draw each power-up
  for _, powerUp in ipairs(player.activePowerUps) do
    local powerUpKey = powerUp.type:upper()
    local powerUpData = GameData.POWERUP_TYPES[powerUpKey]
    
    if powerUpData then
      -- Background with alpha
      love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
      love.graphics.rectangle('fill', powerUpX, powerUpY, powerUpWidth, powerUpHeight, cornerRadius)
      
      -- Power-up name and effect
      love.graphics.setColor(1, 1, 1)
      local effectText = string.format("%s%d%%", powerUpData.description, 
        math.abs((powerUpData.multiplier - 1) * 100))
      love.graphics.print(effectText, powerUpX + padding, powerUpY + 4)
      
      -- Time remaining on the right side
      love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
      local timeText = string.format("%.1fs", powerUp.timeLeft)
      local timeWidth = love.graphics.getFont():getWidth(timeText)
      love.graphics.print(timeText, powerUpX + powerUpWidth - timeWidth - padding, 
        powerUpY + 4)
      
      -- Progress bar
      local barWidth = powerUpWidth - padding * 2
      local barHeight = 3
      -- Bar background
      love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
      love.graphics.rectangle('fill', 
        powerUpX + padding, 
        powerUpY + powerUpHeight - barHeight - 4,
        barWidth,
        barHeight)
      -- Bar fill
      love.graphics.setColor(powerUpData.color[1], powerUpData.color[2], powerUpData.color[3], 0.8)
      love.graphics.rectangle('fill', 
        powerUpX + padding, 
        powerUpY + powerUpHeight - barHeight - 4,
        (powerUp.timeLeft / powerUp.duration) * barWidth,
        barHeight)
      
      powerUpY = powerUpY + powerUpHeight + padding
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

  -- Draw active orbs in top right, below runes
  love.graphics.setFont(hudFont)
  local orbX = Constants.SCREEN_WIDTH - 210  -- Same X position as runes
  local orbY = runeY + 20  -- Start below the last rune
  
  love.graphics.print("Active Orbs:", orbX, orbY)
  orbY = orbY + 25
  
  if player.orbManager then
    for _, orb in ipairs(player.orbManager.orbs) do
      -- Draw orb background
      love.graphics.setColor(orb.color[1], orb.color[2], orb.color[3], 0.3)
      
      local orbWidth = 200
      local orbHeight = 50  -- Fixed height for orb display
      
      love.graphics.rectangle('fill', orbX, orbY, orbWidth, orbHeight)
      
      -- Draw orb name and rank
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(string.format("%s (Rank %d)", 
        orb.type:gsub("^%l", string.upper), -- Capitalize first letter
        orb.rank), 
        orbX + 5, 
        orbY + 2)
      
      -- Draw cooldown bar
      local cooldownWidth = ((orb.cooldown - orb.currentCooldown) / orb.cooldown) * (orbWidth - 10)
      love.graphics.setColor(orb.color[1], orb.color[2], orb.color[3], 0.8)
      love.graphics.rectangle('fill', 
        orbX + 5, 
        orbY + orbHeight - 10, 
        cooldownWidth, 
        5)
      
      orbY = orbY + orbHeight + 5  -- Add small gap between orbs
    end
  end

  -- Reset color and font
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(hudFont)

  -- Draw compass after other HUD elements
  drawCompass(player, runeSpawner)

  -- Draw console last
  console:draw()
end

function love.keypressed(key)
  if key == '`' then
    console:toggle()
    -- When console is active, disable mouse capture
    _G.mouseGrabbed = not console.active
    love.mouse.setVisible(not _G.mouseGrabbed)
    return
  end
  
  if console:handleInput(key) then
    return
  end
  
  if key == 'escape' then
    -- Toggle mouse capture when pressing escape
    _G.mouseGrabbed = not _G.mouseGrabbed
    love.mouse.setVisible(not _G.mouseGrabbed)
    
    -- Only quit if escape is pressed twice while mouse is visible
    if _G.mouseGrabbed then
      return
    end
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

function love.focus(focused)
  -- Release mouse when window loses focus
  if not focused then
    _G.mouseGrabbed = false
    love.mouse.setVisible(true)
  else
    -- Recapture mouse when window regains focus (if not in console)
    if not console.active then
      _G.mouseGrabbed = true
      love.mouse.setVisible(false)
    end
  end
end
