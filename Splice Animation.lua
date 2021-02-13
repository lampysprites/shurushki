-- keep it to one sprite
local sprite = app.activeSprite
-- to close on exit
local temp_sprite = nil

-- default settings
-- stores tags like {name = "str", times = num, *from=num, *to=num}
local sequence = {}
local save = true

-- restore settings
local session = shki_session_splice_ani
if session then
    for i,item in ipairs(session.sequence) do
        sequence[i] = {
            name=item.name,
            times=item.times,
            from=item.from,
            to=item.to
        }
    end
    save = session.save
    
    -- ensure the sprite is open
    local open = false
    for _,spr in ipairs(app.sprites) do 
        if spr.filename == session.sprite then
            open = true
            break
        end
    end

    if not open then
        sprite = app.open(session.sprite)
        if not sprite then 
            app.alert{text="Sprite can not be opened, or no longer exists, settings will be reset."}
            sequence = {}
            local sprite = app.activeSprite
        end
        temp_sprite = sprite
    end
end


local last_tag = app.activeTag or sprite.tags[1]
-- "tag" or "frames"
local mode = "tag"

local dlg
local expdlg, expi, xbounds


function save_session()
    if dlg.data.persistent then
        shki_session_splice_ani = {
            sequence = {},
            sprite = sprite.filename,
            save = dlg.data.persistent
        }
        
        for i,item in ipairs(sequence) do
            shki_session_splice_ani.sequence[i] = {
                name=item.name,
                times=item.times,
                from=item.from,
                to=item.to
            }
        end
    else
        -- as an exception to the rule, remember to not save settings aftwerwards
        -- i think it's less annoying than "consistent" unchecking it every time
        shki_session_atlas.save = false
    end
end


function cancel()
    if layer then
        app.activeSprite:deleteLayer(layer)
    end
    dlg:close()
    if temp_sprite then 
        temp_sprite:close() 
    end
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


function expand_apply()
    local item = sequence[expi]

    if item.name=="frames" then
        item.from = tonumber(expdlg.data.from)
        item.to = tonumber(expdlg.data.to)
    else
        item.name = expdlg.data.tag
    end

    item.times = tonumber(expdlg.data.times)

    expdlg:close()
    refresh()
end


function expand_up()
    local item = table.remove(sequence, expi)
    table.insert(sequence, expi - 1, item)
    refresh()
    expand(expi - 1)
end


function expand_down()
    local item = table.remove(sequence, expi)
    table.insert(sequence, expi + 1, item)
    refresh()
    expand(expi + 1)
end


function expand_remove()
    local item = table.remove(sequence, expi)
    expdlg:close()
    refresh()
end


function clear()
    shki_session_splice_ani = nil
    dlg:close()
    if expdlg then 
        expdlg:close() 
    end
end


function expand(i)
    if expdlg then 
        xbounds = Rectangle(expdlg.bounds)
        expdlg:close() 
        expdlg = nil
    end

    local item = sequence[i]

    expi = i

    expdlg=Dialog()
    expdlg:separator{text="Edit Sequence Item"}

    if item.name == "frames" then        
        expdlg:number{ id="from", label="Start Frame", text=tostring(item.from)}
        expdlg:number{ id="to", label="End Frame", text=tostring(item.to)}
    else
        local tags = {}
    
        for i,tag in ipairs(sprite.tags) do
            table.insert(tags, tag.name)
    
            if tag.name == last_tag then
                last_tag_in = true
            end
        end
    
        -- someone might trip on this but let's hope they will figure it out
        if not last_tag_in then
            table.insert(tags, item.name)
        end

        expdlg:combobox{ id="tag", label="Tag", option=item.name, options=tags}
    end
    
    expdlg:number{ id="times", label="Repeat", text=tostring(item.times)}
    
    -- using empty functions here bc the auto-layout makes things jump around, confusing
    expdlg:button{text="Move Before", onclick=((i > 1) and expand_up or function() end)}
    expdlg:button{text="Move After", onclick=((i < #sequence) and expand_down or function() end)}

    expdlg:button{ text="Remove", onclick=expand_remove}
    expdlg:newrow()
    expdlg:button{ text="OK", onclick=expand_apply}
    expdlg:button{ text="Close" }

    expdlg:show{ wait=false }
        
    if not xbounds then
        xbounds = Rectangle(expdlg.bounds)
    end
    expdlg.bounds = xbounds
end


function go()
    save_session()

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
    if temp_sprite then 
        temp_sprite:close()
    end
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
        local name = tdata.name

        if tdata.name == "frames" then 
            name = name .. " " .. tdata.from .. ":" .. tdata.to
        end

        if tdata.times > 1 then
            name = name .. " (x" .. tdata.times .. ")"
        end

        if i == 1 then 
            dlg:button{ label="Tag Sequence", text=name, 
                onclick=function() expand(i) end }
        else
            dlg:button{ text=name, onclick=function() expand(i) end }
            --function() table.remove(sequence, i) refresh() end }
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
    dlg:check{id="persistent", label="Remember settings", selected=save}
    dlg:button{text="Clear", onclick=clear}
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
    end
    dlg.bounds = bounds
end


if not sprite then
    app.alert("Please open a sprite first!")
elseif #sprite.tags == 0 then
    app.alert("Nothing to do: no tags are defined in this sprite.")
else
    -- one transaction to undo everything at once
    -- app.transaction(function()
        show_dialog()
    -- end)
end