local spr = app.activeSprite
local img = app.activeImage
local sel = spr.selection
local pal = spr.palettes[1]
local plen = #pal

local colorset = {}
local ramp = {}

-- find unique colors
for px in img:pixels() do
    local p = img.cel.position
    if sel:contains(px.x + p.x, px.y + p.y) then
        local c = px()
        if not colorset[c] then
            local col = Color(px())
            if col.alpha > 0 then
                colorset[c] = col
            end
        end
    end
end

-- create the ramp
for i,c in pairs(colorset) do
    table.insert(ramp, c)
end
table.sort(ramp, function(a,b) return a.hsvValue < b.hsvValue end)

-- push to the palette
app.transaction(function()
    pal:resize(plen + #ramp)
    for i,c in ipairs(ramp) do
        pal:setColor(plen + i - 1, c)
    end
end)