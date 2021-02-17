if not app.activeSprite then 
    app.alert("Please open a sprite first!")
end


local dlg = {}
local sprite = app.activeSprite
local gsize = sprite.gridBounds.width or 16
-- "iso", "tri", "square", "diamond"
local mode="iso"


local function draw()
    gsize = tonumber(dlg.data.gsize)
    local lr = sprite:newLayer()
    lr.name="Grid"
    lr.isContinuous = true
    lr.stackIndex=1
    local img = sprite:newCel(lr, 1).image

    local draw_11 = mode == "diamond"
    local draw_21 = mode == "iso" or mode == "tri"
    local draw_01 = mode == "tri" or mode == "square"
    local draw_10 = mode == "square"


    if dlg.data.godd and not mode == "square" then
        -- 1:1 lines
        if draw_11 then
            for x = 0, img.width-1 do
                for y = x%gsize, img.height - 1, gsize do
                    local y2 = y-2*x%gsize
                    img:drawPixel(x, y, dlg.data.gcolor)
                    img:drawPixel(x, y2, dlg.data.gcolor)
                    -- othewrwise the last cell isn't complete
                    img:drawPixel(x, y2+gsize, dlg.data.gcolor)
                    
                end
            end
        end
        
        -- 2:1 lines
        if draw_21 then
            for x = 0, img.width-1 do
                for y = x//2%gsize, img.height - 1, gsize do
                    -- sorry :( the first term changes the nextline location, the second accounts for 1px change in grid width
                    local shim = x%2*x//(gsize-1)%2 + x//(gsize-1)//2
                    local y2 = y - shim - (x-x%2)%gsize - 2
                    img:drawPixel(x, y + shim, dlg.data.gcolor)
                    img:drawPixel(x, y2, dlg.data.gcolor)
                    -- othewrwise the last cell isn't complete
                    
                end
            end
        end

        -- vertical
        if draw_01 then
            for x = 0, img.width-1, gsize-1 do
                for y = 0, img.height - 1 do
                    img:drawPixel(x-1, y, dlg.data.gcolor)
                    
                end
            end
        end

        -- horizontal 
        if draw_10 then
            for x = 0, img.width-1 do
                for y = 0, img.height - 1, gsize do
                    img:drawPixel(x, y-1, dlg.data.gcolor)
                    
                end
            end
        end

    else
        -- 1:1 lines
        if draw_11 then
            for x = 0, img.width-1 do
                for y = x%gsize, img.height - 1, gsize do
                    local y2 = y-2*x%gsize
                    img:drawPixel(x, y, dlg.data.gcolor)
                    img:drawPixel(x, y2-1, dlg.data.gcolor)
                    -- othewrwise the last cell isn't complete
                    img:drawPixel(x, y2-1+gsize, dlg.data.gcolor)
                    
                end
            end
        end

        -- 2:1 lines
        if draw_21 then
            for x = 0, img.width-1 do
                for y = x//2%gsize, img.height - 1, gsize do
                    local y2 = y-(x-x%2)%gsize
                    img:drawPixel(x, y, dlg.data.gcolor)
                    img:drawPixel(x, y2, dlg.data.gcolor)
                    -- othewrwise the last cell isn't complete
                    img:drawPixel(x, y2+gsize, dlg.data.gcolor)
                    
                end
            end
        end

        -- vertical
        if draw_01 then
            for x = 0, img.width-1, gsize do
                for y = 0, img.height - 1 do
                    img:drawPixel(x, y, dlg.data.gcolor)
                    
                end
            end
        end

        -- horizontal 
        if draw_10 then
            for x = 0, img.width-1 do
                for y = 0, img.height - 1, gsize do
                    img:drawPixel(x, y, dlg.data.gcolor)
                    
                end
            end
        end
    end

    app.refresh()
end


local show_dialog

local function refresh()
    dlg:close()
    show_dialog()
end


show_dialog = function()
    dlg = Dialog()

    dlg:separator{text="Draw Grid"}
    dlg:radio{label="Shape", text="Isometric", selected=(mode == "iso"), onclick=function() mode="iso" refresh() end}
    dlg:newrow()
    dlg:radio{text="Isometric Triangle", selected=(mode == "tri"), onclick=function() mode="tri" refresh() end}
    dlg:newrow()
    dlg:radio{text="Square", selected=(mode == "square"), onclick=function() mode="square" refresh() end}
    dlg:newrow()
    dlg:radio{text="Diamond", selected=(mode == "diamond"), onclick=function() mode="diamond" refresh() end}
    dlg:number{id="gsize", label="Size", text=tostring(gsize), decimals=0}
    dlg:check{ id="godd", text="1px corner", selected=false}
    dlg:color{ id="gcolor", label="Color", color=Color(0xbaffffff) }
    dlg:separator()
    dlg:button{id="draw", text="Draw", onclick=function() app.transaction(draw) dlg:close() end, focus=true}
    dlg:button{id="cancel", text="Cancel"}

    dlg:show()
    
end

show_dialog()