function love.load()
  -- Initialize your game here
end

function love.update(_)
  -- Update game state here
end

function love.draw()
  -- Draw your game here
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end