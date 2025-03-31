local Constants = require('src.constants')
local Rune = require('src.rune')
local GameData = require('src.gamedata')
local TextureManager = require('src.rendering.texture_manager')

local Mode7 = {
  texture = nil,
  shader = nil,
  skyTexture = nil,
  enemyTexture = nil,
  projectileTexture = nil,
  textureManager = nil,
  fogColor = {0.1, 0.2, 0.25},
  fogDampening = 0.9,
  fogAlpha = 0.93,
  -- Add camera light as first light, followed by static lights
  lightPositions = {{0, 0}, {300, 300}, {-300, -300}},  -- Camera light + static lights
  lightColors = {{1.0, 0.9, 0.7}, {1.0, 0.7, 0.3}, {1.0, 0.7, 0.3}},  -- Brighter white-ish for camera light
  lightRadii = {500, 300, 300},  -- Smaller radius for camera light
  ambientLight = {0.1, 0.1, 0.1},
  postFpgaEnabled = true,
  postFpgaSettings = {
    noise_amount = 0.001,
    scanline_intensity = 0.1,
    color_depth = 32.0,
    pixel_size = 1.5
  },
  postBloomEnabled = true,  -- Enable by default
  postBloomSettings = {
    threshold = 0.7,    -- Lower threshold to catch more bright areas
    intensity = 0.5,    -- Increased intensity for stronger bloom
    blur_size = 1.5     -- Larger blur for more visible glow
  },
  spookyBushTexture = nil
}

function Mode7:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.textureManager = TextureManager:new()  -- Initialize texture manager
  return o
end

function Mode7:load()
  -- Initialize texture manager first
  self.textureManager:load()
  -- Now we can get the dead tree texture
  self.deadTreeTexture = self.textureManager:getTexture('deadTree')
  self.spookyBushTexture = self.textureManager:getTexture('spookyBush')
  
  -- Set filtering for ground texture
  self.texture = love.graphics.newImage('assets/images/ground.png')
  self.texture:setFilter('nearest', 'nearest')
  self.texture:setWrap('repeat', 'repeat')
  
  -- Set filtering for sky texture
  self.skyTexture = love.graphics.newImage('assets/images/sky.png')
  self.skyTexture:setFilter('nearest', 'nearest')
  self.skyTexture:setWrap('repeat', 'clamp')
  
  -- Load and setup shader
  self.shader = love.graphics.newShader('src/shaders/mode7.glsl')
  self.shader:send('horizonLine', Constants.HORIZON_LINE)
  self.shader:send('cameraHeight', Constants.CAMERA_HEIGHT)
  self.shader:send('maxDistance', Constants.DRAW_DISTANCE)
  self.shader:send('fogColor', self.fogColor)
  self.shader:send('fogDampening', self.fogDampening)
  self.shader:send('fogAlpha', self.fogAlpha)
  self.shader:send('lightColors', unpack(self.lightColors))
  self.shader:send('lightRadii', unpack(self.lightRadii))
  self.shader:send('ambientLight', self.ambientLight)
  
  local w, h = self.texture:getDimensions()
  self.shader:send('textureDimensions', {w, h})
  
  -- Create all canvas textures first
  -- Create more visible rune texture
  local runeCanvas = love.graphics.newCanvas(64, 64)
  love.graphics.setCanvas(runeCanvas)
  love.graphics.clear()

  -- Draw outer glow
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.circle('fill', 32, 32, 30)

  -- Draw main rune circle
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.circle('fill', 32, 32, 24)

  -- Draw decorative elements
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.setLineWidth(3)

  -- Draw octagon
  for i = 1, 8 do
      local angle1 = (i - 1) * math.pi / 4
      local angle2 = i * math.pi / 4
      local x1 = 32 + math.cos(angle1) * 20
      local y1 = 32 + math.sin(angle1) * 20
      local x2 = 32 + math.cos(angle2) * 20
      local y2 = 32 + math.sin(angle2) * 20
      love.graphics.line(x1, y1, x2, y2)
  end

  -- Draw rune symbols
  love.graphics.setLineWidth(4)
  -- Central cross
  love.graphics.line(32, 20, 32, 44)  -- Vertical
  love.graphics.line(20, 32, 44, 32)  -- Horizontal

  -- Draw diagonal accents
  love.graphics.setLineWidth(2)
  for i = 1, 4 do
      local angle = (i - 1) * math.pi / 2
      local x = 32 + math.cos(angle) * 16
      local y = 32 + math.sin(angle) * 16
      love.graphics.circle('fill', x, y, 3)
  end

  love.graphics.setCanvas()
  self.runeTexture = runeCanvas
  self.runeTexture:setFilter('nearest', 'nearest')

  -- Load chest texture
  self.chestTexture = love.graphics.newImage("assets/images/chest.png")
  self.chestTexture:setFilter('nearest', 'nearest')

  -- Create glow texture
  local glowCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(glowCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 16)
  love.graphics.setCanvas()
  self.glowTexture = glowCanvas
  self.glowTexture:setFilter('nearest', 'nearest')

  -- Create temporary textures
  -- Regular enemy texture (triangle shape)
  local enemyCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(enemyCanvas)
  love.graphics.clear()
  love.graphics.setColor(0.8, 0.2, 0.2, 1)  -- Dark red
  love.graphics.polygon('fill', 16, 0, 32, 32, 0, 32)  -- Triangle
  -- Add white border
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(2)
  love.graphics.polygon('line', 16, 0, 32, 32, 0, 32)
  love.graphics.setCanvas()
  self.enemyTexture = enemyCanvas
  self.enemyTexture:setFilter('nearest', 'nearest')  -- Add filtering

  -- Elite enemy texture (diamond shape)
  local eliteCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(eliteCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 0.5, 0, 1)  -- Orange
  love.graphics.polygon('fill', 16, 0, 32, 16, 16, 32, 0, 16)  -- Diamond
  -- Add glowing border
  love.graphics.setColor(1, 0.8, 0, 1)  -- Golden
  love.graphics.setLineWidth(2)
  love.graphics.polygon('line', 16, 0, 32, 16, 16, 32, 0, 16)
  love.graphics.setCanvas()
  self.eliteTexture = eliteCanvas
  self.eliteTexture:setFilter('nearest', 'nearest')  -- Add filtering

  -- Boss texture (pentagonal shape with details)
  local bossCanvas = love.graphics.newCanvas(64, 64)  -- Larger canvas for more detail
  love.graphics.setCanvas(bossCanvas)
  love.graphics.clear()
  -- Main body
  love.graphics.setColor(0.7, 0, 0.7, 1)  -- Purple
  love.graphics.polygon('fill', 
    32, 0,   -- top
    64, 24,  -- right top
    52, 64,  -- right bottom
    12, 64,  -- left bottom
    0, 24    -- left top
  )
  -- Inner details
  love.graphics.setColor(1, 0, 1, 0.5)  -- Lighter purple
  love.graphics.polygon('fill',
    32, 10,  -- top
    52, 24,  -- right
    32, 54,  -- bottom
    12, 24   -- left
  )
  -- Glowing border
  love.graphics.setColor(1, 0.5, 1, 1)  -- Pink glow
  love.graphics.setLineWidth(3)
  love.graphics.polygon('line',
    32, 0,
    64, 24,
    52, 64,
    12, 64,
    0, 24
  )
  love.graphics.setCanvas()
  self.bossTexture = bossCanvas
  self.bossTexture:setFilter('nearest', 'nearest')  -- Add filtering

  -- Create projectile (fireball) texture
  local projectileCanvas = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(projectileCanvas)
  love.graphics.clear()
  
  -- Draw outer glow (orange)
  love.graphics.setColor(1, 0.5, 0, 0.5)  -- Semi-transparent orange
  love.graphics.circle('fill', 8, 8, 8)
  
  -- Draw middle layer (bright orange)
  love.graphics.setColor(1, 0.7, 0, 0.8)  -- More opaque bright orange
  love.graphics.circle('fill', 8, 8, 6)
  
  -- Draw core (bright yellow-white)
  love.graphics.setColor(1, 1, 0.8, 1)  -- Bright yellow-white
  love.graphics.circle('fill', 8, 8, 4)
  
  -- Add some "trailing flames" effect
  love.graphics.setColor(1, 0.3, 0, 0.6)  -- Semi-transparent red-orange
  love.graphics.polygon('fill', 
    0, 8,  -- Left point
    8, 6,  -- Top middle
    8, 10, -- Bottom middle
    4, 8   -- Center point
  )
  
  love.graphics.setCanvas()
  self.projectileTexture = projectileCanvas
  self.projectileTexture:setFilter('nearest', 'nearest')

  local orbCanvas = love.graphics.newCanvas(32, 32)  -- Reduced from 64x64
  love.graphics.setCanvas(orbCanvas)
  love.graphics.clear()

  -- Sparkle effect
  for i = 1, 8 do
      local angle = (i * math.pi / 4)
      local x = 16 + math.cos(angle) * 12
      local y = 16 + math.sin(angle) * 12
      
      -- Draw sparkle points
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle('fill', x, y, 2)
      
      -- Draw lines connecting to center
      love.graphics.setColor(0, 1, 1, 0.5)
      love.graphics.line(16, 16, x, y)
  end

  -- Inner glow
  love.graphics.setColor(0, 1, 1, 0.6)
  love.graphics.circle('fill', 16, 16, 8)

  -- Core
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 4)

  -- Add pulsing highlight
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.arc('fill', 16, 16, 6, 0, math.pi / 2)

  love.graphics.setCanvas()
  self.orbTexture = orbCanvas
  self.orbTexture:setFilter('nearest', 'nearest')  -- Changed to nearest for pixel-art style

  -- Create experience orb texture (add this near other texture creation code)
  local expOrbCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(expOrbCanvas)
  love.graphics.clear()

  -- Sparkle effect
  for i = 1, 8 do
      local angle = (i * math.pi / 4)
      local x = 16 + math.cos(angle) * 12
      local y = 16 + math.sin(angle) * 12
      
      -- Draw sparkle points
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle('fill', x, y, 2)
      
      -- Draw lines connecting to center
      love.graphics.setColor(0, 1, 1, 0.5)
      love.graphics.line(16, 16, x, y)
  end

  -- Inner glow
  love.graphics.setColor(0, 1, 1, 0.6)
  love.graphics.circle('fill', 16, 16, 8)

  -- Core
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 4)

  -- Add pulsing highlight
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.arc('fill', 16, 16, 6, 0, math.pi / 2)

  love.graphics.setCanvas()
  self.expOrbTexture = expOrbCanvas  -- Store as separate texture
  self.expOrbTexture:setFilter('nearest', 'nearest')

  -- Create orbItem texture
  local orbItemCanvas = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(orbItemCanvas)
  love.graphics.clear()
  
  -- Draw outer ring
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.circle('line', 16, 16, 14)
  
  -- Draw inner circle
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', 16, 16, 8)
  
  -- Draw some decorative lines
  love.graphics.setColor(1, 1, 1, 0.6)
  for i = 1, 4 do
    local angle = (i * math.pi / 2)
    local x = 16 + math.cos(angle) * 12
    local y = 16 + math.sin(angle) * 12
    love.graphics.line(16, 16, x, y)
  end

  love.graphics.setCanvas()
  self.orbItemTexture = orbItemCanvas
  self.orbItemTexture:setFilter('nearest', 'nearest')

  -- Create lightning texture
  local lightningCanvas = love.graphics.newCanvas(32, 256)  -- Taller and thinner canvas
  love.graphics.setCanvas(lightningCanvas)
  love.graphics.clear()
  
  -- Draw main lightning bolt
  love.graphics.setColor(1, 1, 1, 0.9)  -- Bright white core
  local points = {
    16, 0,     -- Top point
    12, 50,    -- First zag left
    20, 100,   -- Zag right
    14, 150,   -- Zag left
    22, 200,   -- Zag right
    16, 256    -- Bottom point
  }
  love.graphics.setLineWidth(3)
  love.graphics.line(points)
  
  -- Draw outer glow
  love.graphics.setColor(0.3, 0.3, 1.0, 0.5)  -- Light blue glow
  love.graphics.setLineWidth(6)
  love.graphics.line(points)
  
  -- Add some small branches
  love.graphics.setColor(0.7, 0.7, 1.0, 0.6)
  love.graphics.setLineWidth(2)
  -- Branch 1
  love.graphics.line(12, 50, 8, 70)
  -- Branch 2
  love.graphics.line(20, 100, 24, 120)
  -- Branch 3
  love.graphics.line(14, 150, 10, 170)
  
  love.graphics.setCanvas()
  self.lightningTexture = lightningCanvas
  self.lightningTexture:setFilter('linear', 'linear')  -- Smooth scaling
  
  -- Create fire effect texture
  local fireCanvas = love.graphics.newCanvas(64, 64)
  love.graphics.setCanvas(fireCanvas)
  love.graphics.clear()
  
  -- Draw outer glow
  love.graphics.setColor(1, 0.5, 0, 0.3)  -- Semi-transparent orange
  love.graphics.circle('fill', 32, 32, 30)
  
  -- Draw middle layer
  love.graphics.setColor(1, 0.3, 0, 0.6)  -- More opaque orange-red
  love.graphics.circle('fill', 32, 32, 24)
  
  -- Draw core
  love.graphics.setColor(1, 0.8, 0, 0.8)  -- Bright yellow-orange
  love.graphics.circle('fill', 32, 32, 16)
  
  -- Draw flame details
  for i = 1, 8 do
      local angle = (i * math.pi / 4)
      local length = 28
      local width = 12
      
      -- Draw flame tongues
      love.graphics.setColor(1, 0.2, 0, 0.7)
      local x1 = 32 + math.cos(angle) * 20
      local y1 = 32 + math.sin(angle) * 20
      local x2 = 32 + math.cos(angle) * (length + 8)
      local y2 = 32 + math.sin(angle) * (length + 8)
      local x3 = 32 + math.cos(angle + 0.2) * length
      local y3 = 32 + math.sin(angle + 0.2) * length
      local x4 = 32 + math.cos(angle - 0.2) * length
      local y4 = 32 + math.sin(angle - 0.2) * length
      
      love.graphics.polygon('fill', x1, y1, x3, y3, x2, y2, x4, y4)
      
      -- Add bright tips
      love.graphics.setColor(1, 0.8, 0, 0.9)
      love.graphics.circle('fill', x1, y1, 3)
  end
  
  love.graphics.setCanvas()
  self.fireTexture = fireCanvas
  self.fireTexture:setFilter('linear', 'linear')

  -- Debug print to verify texture creation
  print("Lightning texture created:", self.lightningTexture ~= nil)

  -- Initialize post-processing shader and canvases
  self.postFpgaShader = love.graphics.newShader('src/shaders/post_fpga.glsl')
  self.postCanvas = love.graphics.newCanvas()
  self.tempCanvas = love.graphics.newCanvas()  -- Add temporary canvas
  
  -- Send initial settings to shader
  self.postFpgaShader:send('screen_size', {love.graphics.getWidth(), love.graphics.getHeight()})
  for k, v in pairs(self.postFpgaSettings) do
      self.postFpgaShader:send(k, v)
  end

  -- Initialize bloom shader and canvases
  self.postBloomShader = love.graphics.newShader('src/shaders/post_bloom.glsl')
  self.bloomCanvas1 = love.graphics.newCanvas()
  self.bloomCanvas2 = love.graphics.newCanvas()
  
  -- Send initial settings to shader
  self.postBloomShader:send('screen_size', {love.graphics.getWidth(), love.graphics.getHeight()})
  for k, v in pairs(self.postBloomSettings) do
      self.postBloomShader:send(k, v)
  end

  -- Get the spooky bush texture
  self.spookyBushTexture = self.textureManager:getTexture('spookyBush')
  self.spookyBushTexture:setFilter('nearest', 'nearest')
end

function Mode7:render(camera, enemies, projectiles, experienceOrbs, chests, runes, orbItems, deadTrees, spookyBushes)
  -- First render everything to temp canvas
  love.graphics.setCanvas(self.tempCanvas)
  love.graphics.clear()

  -- Update first light position to match camera
  self.lightPositions[1] = {camera.x, camera.y}
  
  love.graphics.setShader(self.shader)
  self.shader:send('cameraPos', {camera.x, camera.y})
  self.shader:send('cameraAngle', camera.angle)
  self.shader:send('cameraHeight', camera.z)  -- Use camera's z value for height
  self.shader:send('lightPositions', unpack(self.lightPositions))
  self.shader:send('skyTexture', self.skyTexture)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.texture, 
    0, 0, 0, 
    love.graphics.getWidth() / self.texture:getWidth(), 
    love.graphics.getHeight() / self.texture:getHeight()
  )
  
  love.graphics.setShader()
  
  -- Add parameter validation with default empty tables
  enemies = enemies or {}
  projectiles = projectiles or {}
  experienceOrbs = experienceOrbs or {}
  chests = chests or {}
  runes = runes or {}
  orbItems = orbItems or {}

  -- Create a table of all objects to sort
  local allObjects = {}

  -- Add dead trees to render list
  for _, tree in ipairs(deadTrees or {}) do
    local dx = tree.x - camera.x
    local dy = tree.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "deadTree",
      object = tree,
      distance = distance
    })
  end

  -- Add enemies to render list
  for _, enemy in ipairs(enemies) do
    local dx = enemy.x - camera.x
    local dy = enemy.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "enemy",
      object = enemy,
      distance = distance
    })
  end

  -- Add projectiles to render list
  for _, projectile in ipairs(projectiles) do
    local dx = projectile.x - camera.x
    local dy = projectile.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "projectile",
      object = projectile,
      distance = distance
    })
  end

  -- Add experience orbs to render list
  for _, orb in ipairs(experienceOrbs) do
    if orb.x and orb.y then
      local dx = orb.x - camera.x
      local dy = orb.y - camera.y
      local distance = math.sqrt(dx * dx + dy * dy)
      
      table.insert(allObjects, {
        type = "experienceOrb",
        object = orb,
        distance = distance
      })
    end
  end

  -- Add chests to render list
  for _, chest in ipairs(chests) do
    local dx = chest.x - camera.x
    local dy = chest.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "chest",
      object = chest,
      distance = distance
    })
  end

  -- Add runes to render list
  for _, rune in ipairs(runes) do
    local dx = rune.x - camera.x
    local dy = rune.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "rune",
      object = rune,
      distance = distance
    })
  end

  -- Add orbs to render list
  for _, orbItem in ipairs(orbItems) do
    local dx = orbItem.x - camera.x
    local dy = orbItem.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "orbItem",
      object = orbItem,
      distance = distance
    })
  end

  -- Add spooky bushes to render list
  for _, bush in ipairs(spookyBushes or {}) do
    local dx = bush.x - camera.x
    local dy = bush.y - camera.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    table.insert(allObjects, {
      type = "spookyBush",
      object = bush,
      distance = distance
    })
  end

  -- Sort objects by distance (furthest first)
  table.sort(allObjects, function(a, b)
    return a.distance > b.distance
  end)

  -- Draw all objects in sorted order
  for _, obj in ipairs(allObjects) do
    if obj.type == "spookyBush" then
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.spookyBushTexture,
        scale = 150.0 * Constants.SPRITE_SCALE * (obj.object.scale or 1.0),
        heightScale = 1.0,
        useAngleScaling = false,
        rotation = 0
      })
      
    elseif obj.type == "deadTree" then
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.deadTreeTexture,  -- Make sure this texture is initialized
        scale = 300.0 * Constants.SPRITE_SCALE * (obj.object.scale or 1.0),
        heightScale = 1.5,
        useAngleScaling = false,
        rotation = 0  -- Set rotation to 0 to keep trees standing still
      })
    elseif obj.type == "enemy" then
      local enemy = obj.object
      if enemy.isBoss then
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.bossTexture,
          scale = 400.0 * Constants.SPRITE_SCALE,
          heightScale = 2.0,
          useAngleScaling = true
        })
      elseif enemy.isElite then
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.eliteTexture,
          scale = 300.0 * Constants.SPRITE_SCALE,
          heightScale = 1.5,
          useAngleScaling = true
        })
      else
        love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(enemy, camera, {
          texture = self.enemyTexture,
          scale = 200.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = true
        })
      end
    elseif obj.type == "projectile" then
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.projectileTexture,
        scale = 400.0 * Constants.SPRITE_SCALE,
        useAngleScaling = false
      })
    elseif obj.type == "experienceOrb" then
      love.graphics.setColor(0, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.expOrbTexture,  -- Use the experience orb specific texture
        scale = 75.0 * Constants.SPRITE_SCALE,
        heightScale = 1.0,
        useAngleScaling = false
      })
    elseif obj.type == "chest" then
      -- Draw the chest texture
      love.graphics.setColor(1, 1, 1, 1)
      self:drawSprite(obj.object, camera, {
        texture = self.chestTexture,
        scale = 75.0 * Constants.SPRITE_SCALE,
        heightScale = 1.0,
        useAngleScaling = false
      })
      
      -- Add glow effect for unopened chests
      if not obj.object.isOpen then
        love.graphics.setColor(1, 1, 0, 0.5) -- Yellow glow
        self:drawSprite(obj.object, camera, {
          texture = self.glowTexture,
          scale = 100.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = false
        })
      end
    elseif obj.type == "rune" then
      local runeData = Rune.TYPES[obj.object.type]
      if runeData then
        local color = {
          runeData.color[1],
          runeData.color[2],
          runeData.color[3],
          1
        }
        
        self:drawSprite(obj.object, camera, {
          texture = self.runeTexture,
          scale = 50.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = false,
          color = color
        })
      end

    elseif obj.type == "orbItem" then
      self:drawSprite(obj.object, camera, {
          texture = self.orbItemTexture,
          scale = 150.0 * Constants.SPRITE_SCALE,
          heightScale = 1.0,
          useAngleScaling = false,
          color = obj.object.color
      })
    elseif obj.type == "lightning" then
      love.graphics.setColor(1, 1, 1, obj.object.alpha or 1)
      self:drawSprite(obj.object, camera, {
        texture = self.lightningTexture,
        scale = 100.0 * Constants.SPRITE_SCALE,  -- Increased scale
        heightScale = 2.5,  -- Increased height scaling
        useAngleScaling = false,
        heightOffset = -150  -- Adjusted offset to position higher
      })
    end
  end

  -- Render effects
  if _G.effects then
    for _, effect in ipairs(_G.effects) do
      if effect.type == "fire" then
        love.graphics.setColor(1, 1, 1, effect.object.alpha)

        -- Draw multiple fire textures at different scales
        for i = 1, 3 do
          self:drawSprite(effect.object, camera, {            
            texture = self.fireTexture,
            scale = 2.0 * Constants.SPRITE_SCALE * effect.object.scale * (1 + i * 0.2),
            heightScale = 1.0,
            useAngleScaling = false,
            rotation = effect.object.rotation + i * 0.1,
            xOffset = math.random(-1, 1),
            yOffset = math.random(-1, 1),
          })
        end
      end
    end
  end

  -- Explicitly render effects
  if _G.effects then
    for _, effect in ipairs(_G.effects) do
      if effect.type == "lightning" then
        love.graphics.setColor(1, 1, 1, effect.object.alpha or 1)
        self:drawSprite(effect.object, camera, {
          texture = self.lightningTexture,
          scale = 50.0 * Constants.SPRITE_SCALE,
          heightScale = 1.5,
          useAngleScaling = false,
          heightOffset = 0
        })
      end
    end
  end
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  -- After drawing all objects but before HUD, add damage effect
  if _G.player.invulnerableTimer > 0 then
    -- Calculate alpha based on invulnerability timer
    local alpha = math.min(0.1, _G.player.invulnerableTimer / _G.player.invulnerableTime) -- Reduced from 0.4 to 0.2
    
    -- Draw red overlay
    love.graphics.setColor(1, 0, 0, alpha)
    love.graphics.rectangle('fill', 0, 0, 
      love.graphics.getWidth(), 
      love.graphics.getHeight()
    )
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- Copy temp canvas to post canvas
  love.graphics.setCanvas(self.postCanvas)
  love.graphics.clear()
  love.graphics.draw(self.tempCanvas, 0, 0)

  -- Apply bloom if enabled
  if self.postBloomEnabled then
    -- First pass: extract bright parts and blur horizontally
    love.graphics.setCanvas(self.bloomCanvas1)
    love.graphics.clear()
    love.graphics.setShader(self.postBloomShader)
    self.postBloomShader:send('pass', 0)
    love.graphics.draw(self.postCanvas, 0, 0)

    -- Second pass: blur vertically
    love.graphics.setCanvas(self.bloomCanvas2)
    love.graphics.clear()
    self.postBloomShader:send('pass', 1)
    love.graphics.draw(self.bloomCanvas1, 0, 0)

    -- Final composite
    love.graphics.setCanvas(self.tempCanvas)
    love.graphics.clear()
    love.graphics.setShader()
    love.graphics.draw(self.postCanvas, 0, 0)  -- Draw original scene
    love.graphics.setBlendMode('add')          -- Use additive blending for bloom
    love.graphics.draw(self.bloomCanvas2, 0, 0) -- Add bloom on top
    love.graphics.setBlendMode('alpha')        -- Reset blend mode

    -- Copy result back to post canvas
    love.graphics.setCanvas(self.postCanvas)
    love.graphics.clear()
    love.graphics.draw(self.tempCanvas, 0, 0)
  end

  -- Apply FPGA effect if enabled (after bloom)
  if self.postFpgaEnabled then
    love.graphics.setCanvas()
    love.graphics.setShader(self.postFpgaShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.postCanvas, 0, 0)
    love.graphics.setShader()
  else
    -- If FPGA is disabled, render directly to screen
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw(self.postCanvas, 0, 0)
  end
end

function Mode7:drawSprite(entity, camera, options)
    options = options or {}
    local texture = options.texture or self.enemyTexture
    local scale = options.scale or 6.0
    local heightScale = options.heightScale or 1.0
    local useAngleScaling = options.useAngleScaling or false
    local heightOffset = options.heightOffset or 0
    local color = options.color or {1, 1, 1, 1}
    local rotation = options.rotation or 0
    local xOffset = options.xOffset or 0  -- New x offset option
    local yOffset = options.yOffset or 0  -- New y offset option
    
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Apply specified color
    love.graphics.setColor(unpack(color))
    
    -- Calculate screen position
    local dx = (entity.x + xOffset) - camera.x  -- Add xOffset here
    local dy = (entity.y + yOffset) - camera.y  -- Add yOffset here
    
    -- Transform to camera space
    local cosA = math.cos(camera.angle)
    local sinA = math.sin(camera.angle)
    local rx = dx * cosA - dy * sinA
    local ry = dx * sinA + dy * cosA
    
    -- Don't render if behind camera or too far
    if ry <= 0 or ry > Constants.DRAW_DISTANCE then 
        return 
    end
  
  -- Calculate screen position using proper FOV projection
  local fovRadians = math.rad(Constants.FOV)
  local tanHalfFOV = math.tan(fovRadians * 0.5)
  
  -- Project X coordinate using FOV
  local screenX = Constants.SCREEN_WIDTH/2 + 
                 (rx * Constants.SCREEN_HEIGHT) / (ry * tanHalfFOV)
  
  -- Calculate perspective scale using same FOV
  local perspectiveScale = (Constants.SCREEN_HEIGHT) / (ry * tanHalfFOV)
  local spriteScale = perspectiveScale * scale * 0.01
  
  -- Calculate ground position using the same projection as the shader
  local groundY = Constants.HORIZON_LINE + 
                 (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                 (Constants.CAMERA_HEIGHT / ry)
  
  -- Position sprite directly at ground level
  local screenY = groundY
  
  if heightOffset ~= 0 then
    -- Apply height offset after ground plane calculation
    screenY = screenY - (heightOffset * perspectiveScale)
  end

  -- Debug: Draw ground reference point
  -- love.graphics.setColor(1, 0, 0, 1)
  -- love.graphics.circle('fill', screenX, groundY, 2)
  
  -- Draw crosshair if this is the player's current target
  if _G.player and _G.player.currentTarget == entity then
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw targeting crosshair
    love.graphics.setColor(1, 0, 0, 0.8)  -- Red with some transparency
    
    -- Calculate crosshair size based on perspective
    local crosshairSize = 600 * perspectiveScale
    local lineLength = 200 * perspectiveScale
    local bracketSize = 300 * perspectiveScale
    
    -- Draw crosshair lines
    love.graphics.setLineWidth(4)  -- Thicker lines for visibility
    -- Horizontal lines
    love.graphics.line(screenX - crosshairSize, screenY, screenX - lineLength, screenY)
    love.graphics.line(screenX + lineLength, screenY, screenX + crosshairSize, screenY)
    -- Vertical lines
    love.graphics.line(screenX, screenY - crosshairSize, screenX, screenY - lineLength)
    love.graphics.line(screenX, screenY + lineLength, screenX, screenY + crosshairSize)
    
    -- Draw corner brackets
    -- Top-left
    love.graphics.line(screenX - bracketSize, screenY - bracketSize, screenX - bracketSize, screenY - bracketSize/2)
    love.graphics.line(screenX - bracketSize, screenY - bracketSize, screenX - bracketSize/2, screenY - bracketSize)
    -- Top-right
    love.graphics.line(screenX + bracketSize, screenY - bracketSize, screenX + bracketSize, screenY - bracketSize/2)
    love.graphics.line(screenX + bracketSize, screenY - bracketSize, screenX + bracketSize/2, screenY - bracketSize)
    -- Bottom-left
    love.graphics.line(screenX - bracketSize, screenY + bracketSize, screenX - bracketSize, screenY + bracketSize/2)
    love.graphics.line(screenX - bracketSize, screenY + bracketSize, screenX - bracketSize/2, screenY + bracketSize)
    -- Bottom-right
    love.graphics.line(screenX + bracketSize, screenY + bracketSize, screenX + bracketSize, screenY + bracketSize/2)
    love.graphics.line(screenX + bracketSize, screenY + bracketSize, screenX + bracketSize/2, screenY + bracketSize)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    
    -- Restore original color
    love.graphics.setColor(r, g, b, a)
  end
  
  -- Draw the sprite with bottom aligned to ground
  love.graphics.draw(
    texture,
    screenX, screenY,
    rotation,  -- Use rotation parameter here
    spriteScale,  -- width scale
    spriteScale * heightScale,  -- height scale with multiplier
    texture:getWidth() / 2,     -- center horizontally
    texture:getHeight()         -- align bottom with ground
  )
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Draw health bar if entity has health
  if entity.health and entity.health > 0 then
    -- Calculate health bar dimensions
    local barWidth = texture:getWidth() * spriteScale
    local barHeight = 5 * spriteScale  -- Height of health bar
    local barY = screenY - (texture:getHeight() * spriteScale * heightScale / 2) - (barHeight * 2)  -- Position above sprite
    local barX = screenX - (barWidth / 2)
    
    -- Draw background (red)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)
    
    -- Draw health (green) - use maxHealth instead of hardcoded value
    local healthPercent = entity.health / entity.maxHealth
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle('fill', barX, barY, barWidth * healthPercent, barHeight)
    
    -- Draw border
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('line', barX, barY, barWidth, barHeight)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
  end
  
  -- Draw damage number if entity has one
  if entity.damageNumber then
    local num = entity.damageNumber
    -- Calculate damage number position
    local numDx = entity.x - camera.x
    local numDy = entity.y - camera.y
    local numRx = numDx * cosA - numDy * sinA
    local numRy = numDx * sinA + numDy * cosA
    
    -- Skip if behind camera
    if numRy > 0 then
      -- Calculate screen position with perspective
      local numScreenX = Constants.SCREEN_WIDTH/2 + 
                        (numRx * Constants.SCREEN_HEIGHT * 0.5) / numRy
      
      -- Adjust Y position based on floating height (INVERTED)
      local groundY = Constants.HORIZON_LINE + 
                     (Constants.SCREEN_HEIGHT - Constants.HORIZON_LINE) * 
                     (Constants.CAMERA_HEIGHT / numRy)
      
      -- Calculate screen Y with NEGATIVE offset for upward movement
      local numScreenY = groundY - (num.age * 100) -- Move UP by using subtraction
      
      -- Draw damage number with color based on critical
      if num.isCritical then
        love.graphics.setColor(1, 0.5, 0, 1)  -- Orange-yellow for crits
      else
        love.graphics.setColor(1, 1, 0, 1)    -- Yellow for normal hits
      end
      
      love.graphics.push()
      love.graphics.translate(numScreenX, numScreenY)
      -- Bigger scale for crits
      local baseScale = num.isCritical and 2.0 or 1.5
      love.graphics.scale(baseScale, baseScale)
      love.graphics.printf(
        tostring(num.value),
        -50, -10,
        100,
        "center"
      )
      love.graphics.pop()
    end
  end
end

function Mode7:update(dt)
  -- Add subtle torch flicker
  local flickerIntensity = 1.0 + math.sin(love.timer.getTime() * 10) * 0.1
  local flickeringColor = {
    self.lightColor[1] * flickerIntensity,
    self.lightColor[2] * flickerIntensity,
    self.lightColor[3] * flickerIntensity
  }
  self.shader:send('lightColor', flickeringColor)
end

function Mode7:togglePostFpga()
  self.postFpgaEnabled = not self.postFpgaEnabled
  return self.postFpgaEnabled
end

function Mode7:setPostFpgaSetting(setting, value)
  if self.postFpgaSettings[setting] then
    self.postFpgaSettings[setting] = value
    self.postFpgaShader:send(setting, value)
    return true
  end
  return false
end

function Mode7:togglePostBloom()
  self.postBloomEnabled = not self.postBloomEnabled
  return self.postBloomEnabled
end

function Mode7:setPostBloomSetting(setting, value)
  if self.postBloomSettings[setting] then
    self.postBloomSettings[setting] = value
    self.postBloomShader:send(setting, value)
    return true
  end
  return false
end

return Mode7


