function Renderer:renderGameObjects(camera, gameObjects)
    -- Create array of all objects for depth sorting
    local allObjects = {}
    
    -- Add environment objects first
    for _, tree in ipairs(gameObjects.deadTrees or {}) do
        table.insert(allObjects, {
            type = "deadTree",
            object = tree,
            distance = camera:getDistanceTo(tree.x, tree.y)
        })
    end
    
    -- ... existing object handling ...
    
    -- Sort all objects by distance
    table.sort(allObjects, function(a, b)
        return a.distance > b.distance
    end)
    
    -- Draw all objects
    for _, obj in ipairs(allObjects) do
        if obj.type == "deadTree" then
            love.graphics.setColor(1, 1, 1, 1)
            self.spriteRenderer:drawSprite(obj.object, camera, {
                texture = self.textureManager.textures.deadTree,
                scale = 300.0 * Constants.SPRITE_SCALE * obj.object.scale,
                heightScale = 1.5,
                useAngleScaling = false,
                rotation = obj.object.rotation
            })
        end
        -- ... existing object rendering ...
    end
end