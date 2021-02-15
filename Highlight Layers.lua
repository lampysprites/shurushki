--[[ assign colors to the layers, depending on the mode ]]

if app.activeSprite == nil then
    app.alert("Please open a sprite first!")
end

local colors = {
    [BlendMode.NORMAL]=Color(0),
    [BlendMode.MULTIPLY]=Color(0xffff63f7),
    [BlendMode.SCREEN]=Color(0xff47a5f7),
    [BlendMode.OVERLAY]=Color(0xffababab),
    [BlendMode.DARKEN]=Color(0xff815eff),
    [BlendMode.LIGHTEN]=Color(0xff47cbf7),
    [BlendMode.COLOR_DODGE]=Color(0xffffcbf7),
    [BlendMode.COLOR_BURN]=Color(0xff2a2bcf),
    [BlendMode.HARD_LIGHT]=Color(0xfffcfcfc),
    [BlendMode.SOFT_LIGHT]=Color(0xffe6e6e6),
    [BlendMode.DIFFERENCE]=Color(0xffce509b),
    [BlendMode.EXCLUSION]=Color(0xffdf86d1),
    [BlendMode.HSL_HUE]=Color(0xff00920d),
    [BlendMode.HSL_SATURATION]=Color(0xff00ff5e),
    [BlendMode.HSL_COLOR]=Color(0xff82761d),
    [BlendMode.HSL_LUMINOSITY]=Color(0xffb29a7b),
    [BlendMode.ADDITION]=Color(0xffb781f7),
    [BlendMode.SUBTRACT]=Color(0xfff2b957),
    [BlendMode.DIVIDE]=Color(0xfffff78f)
}

app.transaction(function()
    for i,layer in ipairs(app.range.layers) do
        layer.color = colors[layer.blendMode]
    end
end)