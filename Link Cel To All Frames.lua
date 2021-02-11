if not app.activeSprite then
    app.alert("Please open a sprite first.")
end

if not app.activeCel then
    app.alert("Please select a cel to be linked.")
end

app.transaction( function()
    local layers = {}
    local sprite, frame = app.activeSprite, app.activeCel.frameNumber
    local cels_row = {}

    for i,cel in ipairs(sprite.frames) do
        cels_row[i] = i
    end

    -- stash layer references, as range.clean will be called later
    for i,layer in ipairs(app.range.layers) do
        table.insert(layers, layer)
    end

    for k,layer in ipairs(layers) do
        
        -- For some reason, in the script, linking skips empty cels (due to how range works i guess?)
        -- let's create empties where they should go
        for i,cel in ipairs(sprite.frames) do
            if not layer:cel(i) then
                cel = sprite:newCel(layer, i)
            end
        end

        -- we need to link to the active cel, but the app.command links to the first cel, so  let's copy the image to the first
        local proto = layer:cel(1)
        local cel = layer:cel(frame)
        proto.image = cel.image
        proto.position = cel.position
        -- ??? not copying cel.color, cel.opacity etc. is it needed ???

        app.range:clear()
        app.range.layers = {layer}
        app.range.frames = cels_row
        app.command.LinkCels()
        app.range:clear()
    end
end)