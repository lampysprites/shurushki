local tools = { "rectangular_marquee", "elliptical_marquee", "lasso", "polygonal_lasso", "magic_wand", "pencil", 
        "spray", "eraser", "eyedropper", "hand", "move", "slice", "zoom", "paint_bucket", "gradient", "line", 
        "curve", "rectangle", "filled_rectangle", "ellipse", "filled_ellipse", "contour", "polygon", "blur", "jumble" }

-- Base function for color adjustments that hides all overlays and restores them
local color_adjust = function(adjust) 
    return function()
        -- Save curent state
        local tool = app.activeTool
        local onion = app.preferences.document(app.activeSprite).onionskin.active
        local show = app.preferences.document(app.activeSprite).show.selection_edges
        local grid = app.preferences.document(app.activeSprite).show.grid
        local pixel_grid = app.preferences.document(app.activeSprite).show.pixel_grid

        -- Hide everything
        app.activeTool = "hand"
        app.preferences.document(app.activeSprite).onionskin.active = false
        app.preferences.document(app.activeSprite).show.selection_edges = false
        app.preferences.document(app.activeSprite).show.grid = false
        app.preferences.document(app.activeSprite).show.pixel_grid = false

        -- Do the thing
        adjust()

        -- Restore initial state
        app.activeTool = tool
        app.preferences.document(app.activeSprite).onionskin.active = onion
        app.preferences.document(app.activeSprite).show.selection_edges = show
        app.preferences.document(app.activeSprite).show.grid = grid
        app.preferences.document(app.activeSprite).show.pixel_grid = pixel_grid
    end 
end


shki_shortcuts = {
    { name="Common Circle Brush", fn = function() for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.type = BrushType.CIRCLE stroke.size = stroke.size + 1 stroke.size = stroke.size - 1 end end },
    { name="Common Square Brush", fn = function() for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.type = BrushType.SQUARE stroke.size = stroke.size + 1 stroke.size = stroke.size - 1 end end },

    { name="Common Decrease Opacity", fn = function() local fgColor = app.fgColor local alpha = fgColor.alpha - 32 fgColor.alpha = (alpha < 0) and 0 or alpha app.fgColor = fgColor end },
    { name="Common Increase Opacity", fn = function() local fgColor = app.fgColor local alpha = fgColor.alpha + 32 fgColor.alpha = (alpha > 255) and 255 or alpha app.fgColor = fgColor end },
    { name="Common Zero Opacity", fn = function() local fgColor = app.fgColor fgColor.alpha = 0 app.fgColor = fgColor end },
    { name="Common Full Opacity", fn = function() local fgColor = app.fgColor fgColor.alpha = 255 app.fgColor = fgColor end },
    { name="Background Zero Opacity", fn = function() app.bgColor = Color{r=0, g=0, b=0, a=0} end },

    { name="Common Decrement Size", fn = function() local active = app.preferences.tool(app.activeTool).brush active.size = (active.size > 1) and (active.size - 1) or 1 for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.size = active.size end end },
    { name="Common Increment Size", fn = function() local active = app.preferences.tool(app.activeTool).brush active.size = active.size + 1 for _, tool in pairs(tools) do local stroke = app.preferences.tool(tool).brush stroke.size = active.size end end },
    { name="Common Reset Size", fn = function() for _, tool in pairs(tools) do app.preferences.tool(tool).brush.size = 1 end end },
    
    { name="Certain Fill", fn=function() app.preferences.tool("paint_bucket").contiguous = true app.activeTool = "paint_bucket" end },
    { name="Certain Replace Color", fn=function() app.preferences.tool("paint_bucket").contiguous = false app.activeTool = "paint_bucket" end },

    { name="Certain Select Color", fn=function() app.preferences.tool("magic_wand").contiguous = false app.activeTool = "magic_wand" end },
    { name="Certain Select Cluster", fn=function() app.preferences.tool("magic_wand").contiguous = true app.activeTool = "magic_wand" end },

    { name="No Overlay Brightness/Contrast", fn=color_adjust(app.command.BrightnessContrast) },
    { name="No Overlay Hue/Saturation", fn=color_adjust(app.command.HueSaturation) },
    { name="No Overlay Color Curve", fn=color_adjust(app.command.ColorCurve) },

    {name="Invert Visiblity", fn=function() for _,l in ipairs(app.range.layers) do l.isVisible = not l.isVisible end app.refresh() end}
}