-- Test runner main file
local lovetest = require('test.lovetest')
local Constants = require('src.constants')
local Camera = require('src.camera')

-- Mock love.graphics if needed for Camera tests
love = love or {
    graphics = {
        getWidth = function() return 800 end,
        getHeight = function() return 600 end
    }
}

-- Test suite for Camera
lovetest.suite('Camera')

lovetest.test('Camera initialization', function()
  local cam = Camera:new()
  lovetest.assert_eq(cam.x, 0, "Initial x position should be 0")
  lovetest.assert_eq(cam.y, 0, "Initial y position should be 0")
  lovetest.assert_eq(cam.z, Constants.CAMERA_HEIGHT, "Initial z should match CAMERA_HEIGHT")
  lovetest.assert_eq(cam.angle, 0, "Initial angle should be 0")
end)

lovetest.test('Camera reset', function()
  local cam = Camera:new()
  cam.x = 100
  cam.y = 200
  cam.z = 300
  cam.angle = 1.5
  cam.bobPhase = 2.0
  cam.bobActive = true
  
  cam:reset()
  
  lovetest.assert_eq(cam.x, 0, "Reset x position should be 0")
  lovetest.assert_eq(cam.y, 0, "Reset y position should be 0")
  lovetest.assert_eq(cam.z, Constants.CAMERA_HEIGHT, "Reset z should match CAMERA_HEIGHT")
  lovetest.assert_eq(cam.angle, 0, "Reset angle should be 0")
  lovetest.assert_eq(cam.bobPhase, 0, "Reset bobPhase should be 0")
  lovetest.assert_eq(cam.bobActive, false, "Reset bobActive should be false")
end)

lovetest.test('Camera follows player', function()
  local cam = Camera:new()
  local mockPlayer = {
    x = 100,
    y = 200,
    angle = 1.5,
    isDead = false,
    lastX = 100,
    lastY = 200,
    forward = 0,  -- Add these properties
    strafe = 0    -- Add these properties
  }
  
  cam:update(1.0, mockPlayer)
  
  lovetest.assert_eq(cam.x, mockPlayer.x, "Camera should match player x")
  lovetest.assert_eq(cam.y, mockPlayer.y, "Camera should match player y")
  lovetest.assert_eq(cam.angle, mockPlayer.angle, "Camera should match player angle")
end)

lovetest.test('Camera bob effect when moving', function()
  local cam = Camera:new()
  local mockPlayer = {
    x = 100,
    y = 200,
    angle = 0,
    isDead = false,
    lastX = 90,
    lastY = 190,
    forward = 1.0,  -- Add movement values
    strafe = 0.5    -- Add movement values
  }
  
  cam:update(1.0, mockPlayer)
  
  lovetest.assert_eq(cam.bobActive, true, "Bob effect should be active when moving")
  lovetest.assert_near(cam.z, Constants.CAMERA_HEIGHT, cam.bobAmplitude + 0.1, "Z should be within bob amplitude of base height")
end)

lovetest.test('Camera direction vector', function()
  local cam = Camera:new()
  cam.angle = math.pi / 2 -- 90 degrees
  
  local dir = cam:getDirectionVector()
  lovetest.assert_near(dir.x, 1, 0.001, "X component should be 1 at 90 degrees")
  lovetest.assert_near(dir.y, 0, 0.001, "Y component should be 0 at 90 degrees")
end)

lovetest.test('Camera distance calculation', function()
  local cam = Camera:new()
  cam.x = 0
  cam.y = 0
  
  local distance = cam:distanceTo(3, 4)
  lovetest.assert_eq(distance, 5, "Distance should be calculated correctly")
end)

-- Run all tests
if arg[2] == "test" then
  lovetest.run()
end

return lovetest



