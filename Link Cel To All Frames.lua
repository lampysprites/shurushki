if not app.activeSprite then
    app.alert("Please open a sprite first.")
end

if not app.activeCel then
    app.alert("Please select a cel to be linked.")
end

app.transaction( function()
    local sprite, layer, cel = app.activeSprite, app.activeLayer, app.activeCel
    local cels_row = {}

    for i,cel in ipairs(sprite.frames) do
        -- For some reason, in the script, linking skips empty cels (due to how range works i guess?)
        -- let's create empties where they should go
        if not layer:cel(i) then
            cel = sprite:newCel(layer, i)
        end
        cels_row[i] = i
    end

    -- we need to link to the active cel, but the app.command links to the first cel, so  let's copy the image to the first
    local proto = layer:cel(1)
    proto.image = cel.image
    proto.position = cel.position
    -- ??? not copying cel.color, cel.opacity etc. is it needed ???

    app.range:clear()
    app.range.layers = {app.activeLayer}
    app.range.frames = cels_row
    app.command.LinkCels()
    app.range:clear()
end)