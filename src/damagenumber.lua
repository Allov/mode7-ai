local DamageNumber = {
  value = 0,
  x = 0,
  y = 0,
  z = 0,
  age = 0,
  lifetime = 1.0,
  floatSpeed = 50,
  baseScale = 1.0,
  isCritical = false
}

function DamageNumber:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Add init function
function DamageNumber:init(params)
  self.value = params.value
  self.x = params.x
  self.y = params.y
  self.z = params.z
  self.age = 0
  self.isCritical = params.isCritical or false
  self.baseScale = params.baseScale or 1.0
  return self
end

return DamageNumber
