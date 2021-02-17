local sprite = app.activeSprite

if sprite == nil or #app.range.frames < 2 then 
    app.alert("Please open a sprite and select some cels first")
end

local shift = 1
-- we'll need to save links between cels to restore them later. stored as {[Cel]={frameNumber, ...}}
local links = {}
-- also chenge the frame time
local aff_frame=false

-- save this since the range have to change to relink cels
local frames = {}
for i,f in ipairs(app.range.frames) do
    frames[i] = f.frameNumber
end
local layers = {}
for i,l in ipairs(app.range.layers) do
    layers[i] = l
end
-- user's selection will disappear, but at least we can restore the active cel
local restore_l = app.activeLayer
local restore_f = app.activeFrame.frameNumber


-- check for avoiding duplicates in `links`
local function is_recorded(cel) 
    for c,link in pairs(links) do
        if c == cel then 
            return true
        elseif c.layer == cel.layer then
            for i,cc in ipairs(link) do
                if cc == cel.frameNumber then
                    return true
                end
            end
        end
    end

    return false
end


-- copy cel data bc that's the best we got atm
-- will destroy all links :(
local function copy_cel(cel, to_frame)
    if cel == nil then return end

    local layer = cel.layer
    local dest = layer:cel(to_frame)

    if dest == nil then
        dest = sprite:newCel(layer, to_frame, Image(cel.image), Point(cel.position))
    else
        dest.image = Image(cel.image)
        dest.position = Point(cel.position)
    end

    dest.opacity = cel.opacity
    dest.color = cel.color
    dest.data = cel.data

    if aff_frame then 
        dest.frame.duration = cel.frame.duration
    end
end


-- cels are always linked to the same layer, so let's store only frame numbers
-- where they're linked to
local function find_linked(cel)
    local link = {}

    -- this iterator includes cel, it's desired
    for i,c in ipairs(sprite.cels) do
        if c.image == cel.image then
            table.insert(link, c.frameNumber)
        end
    end

    return link
end


local function link_cels(layers, frames)
    app.range:clear()
    app.range.layers=layers
    app.range.frames=frames
    app.command.LinkCels()
end


local function go()
    while shift < 0 do
        shift = #frames + shift
    end

    -- record all links and clear them (or it'll mess up copying)
    for i,cel in ipairs(app.range.cels) do
        if not is_recorded(cel) then
            local linked = find_linked(cel)

            if #linked > 1 then
                links[cel] = linked
            end
        end
    end
    app.command.UnlinkCel()

    -- copy last cels away so they aren't lost when overwritten
    local extra_frame = sprite:newEmptyFrame(1 + #sprite.frames).frameNumber
    for i=2,shift do
        sprite:newEmptyFrame(1 + #sprite.frames)
    end

    for _,layer in ipairs(layers) do
        -- copy into the temp frames
        for i=1,shift do
            local cel = layer:cel(frames[#frames - shift + i])
            copy_cel(cel, extra_frame + i - 1)
        end

        -- move the rest
        for i = #frames-shift, 1, -1 do
            local cel = layer:cel(frames[i])
            copy_cel(cel, frames[i + shift])
        end

        -- get stuff back from the temp frames
        for i=1,shift do
            local cel = layer:cel(extra_frame + i - 1)
            copy_cel(cel, frames[i])
        end
    end

    -- remove extra frames
    while #sprite.frames >= extra_frame do
        sprite:deleteFrame(#sprite.frames)
    end

    -- restore links
    for cel,linked in pairs(links) do
        -- numbers changed
        local linked_new = {}
        for i,n in ipairs(linked) do
            local moved = false
            for j,f in ipairs(frames) do
                if n == f then
                    local newf = j+shift
                    if newf > #frames then 
                        newf = newf - #frames
                    end
                    moved = frames[newf]
                    break
                end
            end

            linked_new[i] = moved or n
        end

        link_cels({cel.layer}, linked_new)
    end

    local restore_cel = restore_l:cel(restore_f)
    if (restore_cel) then
        app.activeCel = restore_cel
    end
end


-- lesgooo
local dlg = Dialog()
dlg:separator{text="Circular Shift"}
dlg:slider{ id="shift", label="# Frames", min=1-#frames, max=#frames-1, value=shift }
dlg:check{ id="frames", label="Affect Duration", selected=false }
dlg:button{ id="ok", text="OK", onclick=function() 
        shift=tonumber(dlg.data.shift) 
        aff_frame=dlg.data.frames
        if shift ~= 0 and #app.range.cels > 1 then
            app.transaction(go) 
        end
        dlg:close() 
end }
dlg:button{ id="cancel", text="Cancel"}
dlg:show()