local dlg = Dialog()

-- restore settings when dialog reopens
local session = shki_session_bitmap_text
local duration, margin, carryover, save
if session then 
    duration = session.duration
    margin = session.margin
    carryover = session.carryover
    save = session.save
else
    duration = 42
    margin = 1
    carryover = false
    save = true
end

dlg:separator{text="Resample"}
dlg:number{ id="duration", label="Duration", text=tostring(duration)}
dlg:number{ id="margin", label="Margin", text=tostring(margin)}
dlg:check{id="carryover", label="Carry Over", selected=carryover}
dlg:separator()
dlg:check{id="persistent", label="Remember settings", selected=save}
dlg:button{id="ok", text="OK"}
dlg:button{text="Cancel"}

dlg:show()

if dlg.data.ok then 
    app.transaction(function()
        local spr = app.activeSprite
        local t = 0
        local f = 1 -- frame index

        -- iterate forwards to keep track of carryover
        while f <= #spr.frames do 
            local frame = spr.frames[f]
            local created = 0
            local newframes = {}

            t = t + math.floor(frame.duration * 1000)

            while t > dlg.data.duration - dlg.data.margin do
                t = t - dlg.data.duration
                created = created + 1
                spr:newFrame(f)
            end

            for i=f,f+created do
                spr.frames[i].duration = dlg.data.duration / 1000
                table.insert(newframes, spr.frames[i])
            end

            -- link cels
            for _,layer in ipairs(spr.layers) do
                app.range.layers = {layer}
                app.range.frames = newframes
                app.command.LinkCels()
            end

            if not dlg.data.carryover then
                t = 0
            end

            f = f + created + 1
        end
    end) -- transaction
end

if dlg.data.persistent then 
    shki_session_bitmap_text = {
        duration = dlg.data.duration,
        margin = dlg.data.margin,
        carryover = dlg.data.carryover,
        save = dlg.data.persistent
    }
else
    -- as an exception to the rule, remember to not save settings aftwerwards
    -- i think it's less annoying than "consistent" unchecking it every time
    shki_session_bitmap_text.save = false
end