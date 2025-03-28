-- Test runner main file
local lovetest = require('test.lovetest')
local Camera = require('src.camera')

-- Test suite for Camera
lovetest.suite('Camera')

lovetest.test('Camera initialization', function()
  local cam = Camera:new()
  lovetest.assert_eq(cam.x, 0, "Initial x position should be 0")
  lovetest.assert_eq(cam.y, 0, "Initial y position should be 0")
  lovetest.assert_eq(cam.z, 100, "Initial z position should be 100")
  lovetest.assert_eq(cam.angle, 0, "Initial angle should be 0")
end)

lovetest.test('Camera movement vectors', function()
  local cam = Camera:new()
  
  -- Test forward movement
  cam.forward = -1 -- W key
  cam.strafe = 0
  cam.angle = 0
  cam:update(1) -- 1 second delta time
  lovetest.assert_near(cam.y, cam.moveSpeed, 0.001, "Should move forward along Y axis")
  
  -- Reset position
  cam.x = 0
  cam.y = 0
  
  -- Test strafe movement
  cam.forward = 0
  cam.strafe = 1 -- D key
  cam.angle = 0
  cam:update(1)
  lovetest.assert_near(cam.x, cam.strafeSpeed, 0.001, "Should strafe right along X axis")
end)

lovetest.test('Camera rotation', function()
  local cam = Camera:new()
  cam.rotation = 1 -- Q key
  cam:update(1)
  lovetest.assert_near(cam.angle, cam.turnSpeed, 0.001, "Should rotate by turnSpeed radians")
end)

-- Run all tests when in test mode
if arg[1] == "test" then
  lovetest.run()
end

return lovetest