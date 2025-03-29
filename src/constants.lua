return {
  SCREEN_WIDTH = 1280,
  SCREEN_HEIGHT = 720,
  SCALE = 2,
  
  -- Mode 7 specific constants
  HORIZON_LINE = 100,
  FOV = 75,  -- Keep the 75 degree FOV, remove CAMERA_FOV
  DRAW_DISTANCE = 1500,  -- This now controls the fog distance
  SPRITE_SCALE = 0.5,    -- Global sprite scale multiplier

  -- Camera settings
  CAMERA_MOVE_SPEED = 200,    -- Base movement speed
  CAMERA_STRAFE_SPEED = 150,  -- Sideways movement speed
  CAMERA_TURN_SPEED = 3,      -- Rotation speed in radians/second
  CAMERA_HEIGHT = 100,        -- Camera height above ground
}


