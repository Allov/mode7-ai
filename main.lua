-- Root main.lua - Entry point
if arg[1] == "test" then
  -- Run tests
  require('test.main')
else
  -- Normal game execution
  require('src.main')
end


