
local dlg = Dialog()

local function go()
    local newrange = {}
    local take, skip = dlg.data.take, dlg.data.skip
    local shift = dlg.data.shift
    local range

    if dlg.data.srel then
        shift = shift + app.range.frames[1].frameNumber - 1
    end

    if dlg.data.rel then
        range = app.range.frames
    else 
        range = app.activeSprite.frames
    end

    for i,frame in ipairs(range) do
        if (frame.frameNumber - shift - 1) % (take + skip) < take then
            table.insert(newrange, frame.frameNumber)
        end
    end

    app.range:clear()
    app.activeFrame = newrange[1] or 1
    app.range.frames = newrange

    if #newrange == 0 then 
        app.alert("Nothing matched the pattern")
        return 
    end
end

dlg
    :number{id="take", label="Select", text="1", decimals=0, focus=true}
    :number{id="skip", label="Skip", text="2", decimals=0, focus=true}
    :number{id="shift", label="Offset By", text="0", decimals=0, focus=true}
    :check{id="rel", label="From Selection"}
    :check{id="srel", label="Shift To Selection"}
    :button{text="Cancel", onclick=function() dlg:close() end}
    :button{text="OK", focus=true, onclick=function() go() dlg:close() end}
    :show{wait=false}