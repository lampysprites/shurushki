
local dlg = Dialog()

-- default settings
local take = 1
local skip = 1
local shift = 0
local rel = false
local srel = false
local save = true


-- restore settings when dialog reopens
local session = shki_session_select_pattern
if session then 
    take = session.take
    skip = session.skip
    shift = session.shift
    rel = session.rel
    srel = session.srel
end


function save_session()
    if dlg.data.persistent then
        shki_session_select_pattern = {
            take = session.take,
            skip = session.skip,
            shift = session.shift,
            rel = session.rel,
            srel = session.srel,
            save = dlg.data.persistent
        }
    else
        -- as an exception to the rule, remember to not save settings aftwerwards
        -- i think it's less annoying than "consistent" unchecking it every time
        shki_session_select_pattern.save = false
    end
end


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
    :number{id="take", label="Select", text=tostring(take), decimals=0, focus=true}
    :number{id="skip", label="Skip", text=tostring(skip), decimals=0, focus=true}
    :number{id="shift", label="Offset By", text=tostring(shift), decimals=0, focus=true}
    :check{id="rel", label="From Selection", selected=rel}
    :check{id="srel", label="Shift To Selection", selected=srel}
    :separator()
    :check{id="persistent", label="Remember settings", selected=save}
    :button{text="Cancel", onclick=function() dlg:close() end}
    :button{text="OK", focus=true, onclick=function() go() dlg:close() end}
    :show{wait=false}