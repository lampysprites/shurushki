if not app.activeSprite then
    app.alert("Please open a sprite first.")
end

app.transaction(function()
    local sprite = app.activeSprite
    local frame = app.range.frames[1]

    for _,layer in ipairs(app.range.layers) do
        local cels = {}
        for i,cel in ipairs(app.range.cels) do
            if cel.layer == layer then
                table.insert(cels, cel)
            end
        end

        for i,cel in ipairs(cels) do 
            local newlayer = sprite:newLayer()
            newlayer.stackIndex = layer.stackIndex + i
            newlayer.name = layer.name .. " Cel" .. cel.frameNumber
            sprite:newCel(newlayer, frame, cel.image, cel.position)
            sprite:deleteCel(cel.layer, cel.frame)
        end
    end

    app.activeFrame = frame
end) -- transaction