-- stores tags like {name = "str", times = num}
local sequence = {}
-- keep it to one sprite
local sprite = app.activeSprite

local last_tag = app.activeTag or sprite.tags[1]
-- "tag" or "frames"
local mode = "tag"


function cancel()
    if layer then
        app.activeSprite:deleteLayer(layer)
    end
    dlg:close()
    app.refresh() -- sometimes it doesn't update :(
end


function refresh()
    local rect = Rectangle(dlg.bounds)

    last_tag = dlg.data.tag

    dlg:close()
    show_dialog(rect)
end


function add_tag()
    local times = tonumber(dlg.data.times)

    if times >= 1 then
        table.insert(sequence, {name = dlg.data.tag, times = times})
    end

    refresh()
end


function add_frames()
    local times = tonumber(dlg.data.times)
    local from, to =  tonumber(dlg.data.from), tonumber(dlg.data.to)

    if not sprite.frames[from] or not sprite.frames[to] then
        app.alert("Requested frame is outside of the sprite's timeline.")
        return
    end

    if times >= 1 then
        table.insert(sequence, {name = "frames", times = times, 
            from = from, to = to})
    end

    refresh()
end


function go()
    local patty = Sprite(sprite)
    local spliced = Sprite(sprite.spec)
    patty:flatten()

    for i,tdata in ipairs(sequence) do
        local from,to = 1,1

        if tdata.name == "frames" then
            from = tdata.from
            to = tdata.to
        else
            for i,t in ipairs(patty.tags) do
                if t.name == tdata.name then
                    from = t.fromFrame.frameNumber
                    to = t.toFrame.frameNumber
                    break
                end
            end
        end

        for i=1,tonumber(tdata.times) do
            for frame=from,to do
                local tlend = #spliced.frames + 1
                local cel = patty.layers[1]:cel(frame)
                local new_frame = spliced:newEmptyFrame(tlend)

                -- copy timing
                new_frame.duration = patty.frames[frame].duration
                -- copy image data
                spliced:newCel(spliced.layers[1], tlend, Image(cel.image), cel.position)
            end
        end
    end

    -- drop the default empty frame
    spliced:deleteFrame(1)

    patty:close()

    dlg:close()
end


function show_dialog(bounds)
    dlg = Dialog()
    dlg:separator{text="Splice Animation"}

    -- create options for tag selector
    local tags = {}
    local last_tag_in = false

    for i,tag in ipairs(sprite.tags) do
        table.insert(tags, tag.name)

        if tag.name == last_tag then
            last_tag_in = true
        end
    end

    if not last_tag_in then
        if app.activeSprite == sprite then 
            last_tag = app.activeTag or sprite.tags[1]
        else
            last_tag = sprite.tags[1]
        end
    end

    if #sequence == 0 then
        dlg:label{label="Sequence", text="(use buttons below to add tags or frames here)"}
    end

    for i,tdata in ipairs(sequence) do
        local name = "- " .. tdata.name

        if tdata.name == "frames" then 
            name = name .. " " .. tdata.from .. ":" .. tdata.to
        end

        if tdata.times > 1 then
            name = name .. " (x" .. tdata.times .. ")"
        end

        if i == 1 then 
            dlg:button{ label="Tag Sequence", text=name, 
                onclick = function() table.remove(sequence, i) refresh() end }
        else
            dlg:button{ text=name, onclick = function() table.remove(sequence, i) refresh() end }
        end
        dlg:newrow()
    end

    if mode == "tag" then
        dlg:combobox{ id="tag", label="Add Tag", option=last_tag, options=tags, focus=(#sequence == 0)}
        dlg:number{ id="times", label="Repeat", text="1", focus=(#sequence ~= 0)}
        dlg:button{text="+ Add", onclick=add_tag}
        dlg:button{text="> Frames", onclick=function() mode="frames" refresh() end }
    else 
        dlg:number{ id="from", label="Start Frame", text="1", focus=true}
        dlg:number{ id="to", label="End Frame", text="1", focus=true}
        dlg:number{ id="times", label="Repeat", text="1"}
        dlg:button{text="+ Add", onclick=add_frames}
        dlg:button{text="> Tag", onclick=function() mode="tag" refresh() end }
    end

    dlg:separator()
    dlg:button{text="Refresh", onclick=refresh}
    if #sequence >= 1 then 
        dlg:button{text="OK", onclick=go} 
    end
    dlg:button{text="Cancel", onclick=cancel}

    
    dlg:show{wait = false}
    
    if bounds then
        bounds.height = dlg.bounds.height
    else
        bounds = Rectangle(dlg.bounds)
        bounds.width = 256
    end
    dlg.bounds = bounds
end


if not sprite then
    app.alert("Please open a sprite first!")
elseif #sprite.tags == 0 then
    app.alert("Nothing to do: no tags are defined in this sprite.")
else
    -- one transaction to undo everything at once
    app.transaction(function()
        show_dialog()
    end)
end