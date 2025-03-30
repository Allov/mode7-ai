local OrbItemManager = {
    items = {},
    player = nil
}

function OrbItemManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OrbItemManager:init(player)
    self.player = player
    self.items = {}
    return self
end

function OrbItemManager:addItem(orbItem)
    table.insert(self.items, orbItem)
    -- Update global reference
    _G.orbItems = self.items
end

function OrbItemManager:getItems()
    return self.items
end

function OrbItemManager:removeItem(orbItem)
    for i, item in ipairs(self.items) do
        if item == orbItem then
            table.remove(self.items, i)
            -- Update global reference
            _G.orbItems = self.items
            return true
        end
    end
    return false
end

function OrbItemManager:update(dt)
    -- Update and cleanup collected orbs
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        if item.collected then
            table.remove(self.items, i)
        end
    end
    
    -- Ensure global items table is updated
    _G.orbItems = self.items
end

return OrbItemManager