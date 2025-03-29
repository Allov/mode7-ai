local Console = {
  isVisible = false,
  inputBuffer = "",
  history = {},
  historyIndex = 1,
  maxHistory = 50,
  outputLines = {},
  maxOutputLines = 10,
  font = nil,
  padding = 5,
  lineHeight = 20,
  backgroundColor = {0, 0, 0, 0.8},
  textColor = {1, 1, 1, 1},
  
  -- Move commands into Console table
  commands = {
    help = {
      desc = "Show available commands",
      func = function(self)
        self:print("Available commands:")
        for cmd, info in pairs(self.commands) do
          self:print(string.format("  %-20s %s", cmd, info.desc))
        end
      end
    },
    
    spawn = {
      desc = "Spawn enemies: spawn <count>",
      func = function(self, args)
        local count = tonumber(args[1]) or 1
        for i = 1, count do
          _G.spawnEnemy()
        end
        self:print(string.format("Spawned %d enemies", count))
      end
    },
    
    killall = {
      desc = "Kill all enemies",
      func = function(self)
        local count = #_G.enemies
        _G.enemies = {}
        self:print(string.format("Killed %d enemies", count))
      end
    },
    
    boss = {
      desc = "Spawn a boss",
      func = function(self)
        _G.spawnBoss()
        self:print("Spawned boss")
      end
    },
    
    reset = {
      desc = "Reset the game",
      func = function(self)
        _G.initializeGame()
        self:print("Game reset")
      end
    },
    
    stats = {
      desc = "Show game statistics",
      func = function(self)
        local stats = love.graphics.getStats()
        self:print(string.format("FPS: %d", love.timer.getFPS()))
        self:print(string.format("Memory: %.2f MB", collectgarbage("count") / 1024))
        self:print(string.format("Drawcalls: %d", stats.drawcalls))
        self:print(string.format("Entities: %d enemies, %d projectiles", #_G.enemies, #_G.projectiles))
      end
    },
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


