local Enemy = require('src.enemy')
local GameData = require('src.gamedata')

local Console = {
  isVisible = false,
  inputText = "",
  outputLines = {},
  maxOutputLines = 10,
  backgroundColor = {0, 0, 0, 0.8},  -- Semi-transparent black
  textColor = {1, 1, 1, 1},          -- White text
  padding = 10,                       -- Padding around text
  lineHeight = 20,                    -- Height of each line
  history = {},                       -- Command history
  maxHistory = 50,                    -- Maximum number of commands to remember
  historyIndex = 1,                   -- Current position in history
  inputBuffer = "",                   -- Current input text
  commands = {
    help = {
      desc = "Show available commands",
      func = function(self)
        self:print("Available commands:")
        for cmd, info in pairs(self.commands) do
          self:print(string.format("  %s: %s", cmd, info.desc))
        end
      end
    },
    
    clear = {
      desc = "Clear console output",
      func = function(self)
        self.outputLines = {}
      end
    },
    
    reset = {
      desc = "Reset the game",
      func = function(self)
        _G.initializeGame()
        self:print("Game reset")
      end
    },
    
    boss = {
      desc = "Spawn a boss",
      func = function(self)
        _G.spawnBoss()
        self:print("Boss spawned")
      end
    },
    
    chest = {
      desc = "Spawn a chest",
      func = function(self)
        _G.spawnChest()
        self:print("Spawned chest")
      end
    },
    
    mobs = {
      desc = "Spawn N enemies (with elite chance): mobs <count>",
      func = function(self, args)
        local count = tonumber(args[1]) or 1
        local spawned = 0
        local elites = 0
        
        for i = 1, count do
          -- Find valid spawn position
          local spawnX, spawnY = _G.findValidSpawnPosition()
          
          -- Only spawn if valid position found
          if spawnX and spawnY then
            -- 10% chance to spawn an elite enemy
            local isElite = math.random() < 0.10
            
            -- Create new enemy with proper initialization
            local enemy = Enemy:new()
            enemy.x = spawnX
            enemy.y = spawnY
            enemy.isElite = isElite
            
            -- Apply elite properties if needed
            if isElite then
              enemy.health = enemy.health * enemy.eliteMultiplier
              enemy.radius = enemy.radius * enemy.eliteScale
              enemy.damageAmount = enemy.damageAmount * enemy.eliteMultiplier
            end
            
            -- Add to global enemies table
            table.insert(_G.enemies, enemy)
            
            -- Debug print to verify spawn
            print(string.format("Spawned enemy at X:%.1f Y:%.1f Elite:%s", 
                              spawnX, spawnY, tostring(isElite)))
            
            spawned = spawned + 1
            if isElite then
              elites = elites + 1
            end
          end
        end
        
        self:print(string.format("Spawned %d enemies (%d elites)", spawned, elites))
        -- Debug print total enemies
        print("Total enemies: " .. #_G.enemies)
      end
    },
    
    rune = {
      desc = "Spawn a rune: rune [type]. Type 'rune list' to see available types",
      func = function(self, args)
        if not args[1] or args[1] == "list" then
          self:print("Available rune types:")
          for runeType, data in pairs(GameData.RUNE_TYPES) do
            self:print(string.format("  %s: %s", runeType, data.description))
          end
          return
        end
        
        local runeType = string.upper(args[1])
        if not GameData.RUNE_TYPES[runeType] then
          self:print("Invalid rune type: " .. args[1])
          self:print("Type 'rune list' to see available types")
          return
        end  -- Changed from } to end
        
        -- Find spawn position in front of player
        local dirVector = _G.camera:getDirectionVector()
        local spawnDistance = 200  -- Spawn 200 units in front of player
        local spawnX = _G.player.x + dirVector.x * spawnDistance
        local spawnY = _G.player.y + dirVector.y * spawnDistance
        
        -- Create and add new rune
        local rune = _G.Rune:new():init(spawnX, spawnY, runeType)
        table.insert(_G.runes, rune)
        
        self:print(string.format("Spawned %s rune at X:%.1f Y:%.1f", 
          GameData.RUNE_TYPES[runeType].name, spawnX, spawnY))
      end
    }
  }
}

function Console:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.font = love.graphics.newFont(14)
  return o
end

function Console:print(text)
  table.insert(self.outputLines, text)
  if #self.outputLines > self.maxOutputLines then
    table.remove(self.outputLines, 1)
  end
end

function Console:toggle()
  self.isVisible = not self.isVisible
  if self.isVisible then
    love.keyboard.setKeyRepeat(true)
    _G.isPaused = true  -- Pause the game when console is opened
  else
    love.keyboard.setKeyRepeat(false)
    _G.isPaused = false  -- Unpause the game when console is closed
  end
end

function Console:execute(command)
  -- Add to history
  table.insert(self.history, command)
  if #self.history > self.maxHistory then
    table.remove(self.history, 1)
  end
  self.historyIndex = #self.history + 1
  
  -- Parse command and arguments
  local args = {}
  for word in command:gmatch("%S+") do
    table.insert(args, word)
  end
  
  if #args == 0 then return end
  
  local cmd = table.remove(args, 1)
  
  -- Execute command if it exists
  if self.commands[cmd] then
    self.commands[cmd].func(self, args)
  else
    self:print("Unknown command: " .. cmd)
    self:print("Type 'help' for available commands")
  end
end

function Console:handleInput(key)
  if not self.isVisible then return false end
  
  if key == "return" then
    if self.inputBuffer ~= "" then
      self:execute(self.inputBuffer)
      self.inputBuffer = ""
    end
  elseif key == "backspace" then
    self.inputBuffer = self.inputBuffer:sub(1, -2)
  elseif key == "up" then
    if self.historyIndex > 1 then
      self.historyIndex = self.historyIndex - 1
      self.inputBuffer = self.history[self.historyIndex]
    end
  elseif key == "down" then
    if self.historyIndex < #self.history then
      self.historyIndex = self.historyIndex + 1
      self.inputBuffer = self.history[self.historyIndex]
    else
      self.historyIndex = #self.history + 1
      self.inputBuffer = ""
    end
  elseif key == "escape" then
    self:toggle()
  end
  
  return true
end

function Console:textinput(text)
  if not self.isVisible then return false end
  self.inputBuffer = self.inputBuffer .. text
  return true
end

function Console:draw()
  if not self.isVisible then return end
  
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(self.font)
  
  -- Draw background
  love.graphics.setColor(self.backgroundColor)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 
    (#self.outputLines + 2) * self.lineHeight + self.padding * 2)
  
  -- Draw output lines
  love.graphics.setColor(self.textColor)
  for i, line in ipairs(self.outputLines) do
    love.graphics.print(line, self.padding, 
      self.padding + (i - 1) * self.lineHeight)
  end
  
  -- Draw input line
  love.graphics.print("> " .. self.inputBuffer .. "_", 
    self.padding, 
    self.padding + #self.outputLines * self.lineHeight)
  
  love.graphics.setFont(oldFont)
end

return Console










