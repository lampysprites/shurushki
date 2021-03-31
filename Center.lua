local dlg = Dialog()
    :separator{ text="Center" }
    :check{ id="horizontal", label="horizontal", selected=true }
    :check{ id="vertical", label="vertical", selected=true }
    :button{ id="cancel", text="Cancel" }
    :button{ id="ok", text="OK", focus=true }
    :show()

if dlg.data.ok then
    local rect = app.range.cels[1].bounds
    local frame = app.activeSprite.selection.isEmpty and app.activeSprite.bounds or app.activeSprite.selection.bounds

    for _,cel in ipairs(app.range.cels) do
        rect = rect:union(cel.bounds)
    end

    local dx, dy = 0, 0

    if dlg.data.horizontal then 
        dx = frame.x + (frame.width - rect.width) // 2 - rect.x
    end

    if dlg.data.vertical then 
        dy = frame.y + (frame.height - rect.height) // 2 - rect.y
    end

    for _,cel in ipairs(app.range.cels) do
        cel.position = Point(cel.position.x + dx, cel.position.y + dy)
    end

    app.refresh()
end