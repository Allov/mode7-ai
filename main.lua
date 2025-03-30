-- Root main.lua - Entry point
if arg[2] == "test" then
    -- Run tests only
    require('test.main')
    return  -- Add return to prevent executing game code
else
    -- Normal game execution
    require('src.main')
end



