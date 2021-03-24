local tools = { "pencil", "spray", "eraser", "line", "curve", "rectangle", "ellipse" }

shki_shortcuts = {
    { name="Common Circle Brush", fn = function() for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.type = BrushType.CIRCLE stroke.size = stroke.size + 1 stroke.size = stroke.size - 1 end end },
    { name="Common Square Brush", fn = function() for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.type = BrushType.SQUARE stroke.size = stroke.size + 1 stroke.size = stroke.size - 1 end end },

    { name="Common Decrease Opacity", fn = function() local fgColor = app.fgColor local alpha = fgColor.alpha - 32 fgColor.alpha = (alpha < 0) and 0 or alpha app.fgColor = fgColor end },
    { name="Common Increase Opacity", fn = function() local fgColor = app.fgColor local alpha = fgColor.alpha + 32 fgColor.alpha = (alpha > 255) and 255 or alpha app.fgColor = fgColor end },
    { name="Common Zero Opacity", fn = function() local fgColor = app.fgColor fgColor.alpha = 0 app.fgColor = fgColor end },
    { name="Common Full Opacity", fn = function() local fgColor = app.fgColor fgColor.alpha = 255 app.fgColor = fgColor end },

    { name="Common Decrement Size", fn = function() local active = app.preferences.tool(app.activeTool).brush active.size = (active.size > 1) and (active.size - 1) or 1 for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.size = active.size end end },
    { name="Common Increment Size", fn = function() local active = app.preferences.tool(app.activeTool).brush active.size = active.size + 1 for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.size = active.size end end },
    { name="Common Reset Size", fn = function() for _, tool in pairs(tools) do app.preferences.tool(tool).brush.size = 1 end end },
    
    { name="Certain Fill", fn=function() app.preferences.tool("paint_bucket").contiguous = true app.activeTool = "paint_bucket" end },
    { name="Certain Replace Color", fn=function() app.preferences.tool("paint_bucket").contiguous = false app.activeTool = "paint_bucket" end },

    { name="Certain Select Color", fn=function() app.preferences.tool("magic_wand").contiguous = false app.activeTool = "magic_wand" end },
    { name="Certain Select Cluster", fn=function() app.preferences.tool("magic_wand").contiguous = true app.activeTool = "magic_wand" end }
}