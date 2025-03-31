-- Get desktop dimensions
local desktopWidth, desktopHeight = love.window.getDesktopDimensions()

return {
  -- Default to desktop resolution
  SCREEN_WIDTH = desktopWidth,
  SCREEN_HEIGHT = desktopHeight,
  SCALE = 2,
  
  -- Mode 7 specific constants
  HORIZON_LINE = 100,
  FOV = 75,
  DRAW_DISTANCE = 1200,
  SPRITE_SCALE = 0.5,

  -- Camera settings
  CAMERA_MOVE_SPEED = 200,
  CAMERA_STRAFE_SPEED = 150,
  CAMERA_TURN_SPEED = 3,
  CAMERA_HEIGHT = 100,
}


