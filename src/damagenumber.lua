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

return DamageNumber