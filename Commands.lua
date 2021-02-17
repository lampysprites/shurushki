function run_script(f) 
    local s = app.fs.joinPath(app.fs.userConfigPath, "extensions", "shurushki", f) .. ".lua"

    return function()
        dofile(s)
    end
end


-- create a copy of a table when needed
local function all_commands()
    return {
        { name="Bitmap Text", group="edit_fill", location="Edit > Bitmap Text" },
        { name="Draw Grid", group="edit_fill", location="Edit > Draw Grid" },
        { name="Export Atlas", group="file_export", location="File > Export Atlas" },
        { name="Frame Pattern", group="select_simple", location="Select > Frame Pattern" },
        { name="Gamma Gradient", group="palette_generation", location="Color Bar > Options > Gamma Gradient" },
        { name="Highlight Cels", group="view_animation_helpers", location="View > Highlight Layers" },
        { name="Highlight Layers", group="view_animation_helpers", location="View > Highlight Layers" },
        { name="Link Active", group="cel_popup_links", location="Timeline > Cel > Right Click" },
        { name="Link To All Frames", group="cel_popup_links", location="Timeline > Cel > Right Click"},
        { name="Move Cels", group="edit_transform", location="Edit > Move Cels" },
        { name="Splice Animation", group="file_export", location="File > Splice Animation"},
        { name="Time Stretch", group="cel_frames", location="Frame > Time Stretch" },
        { name="Circular Shift", group="cel_popup_links", location="Timeline > Cel > Right Click" },
    }
end
-- a copy to use as a reference
local commands = all_commands()


local function settings_dialog(prefs, firsttime)
    -- prepare and show dialog
    local dlg = Dialog()

    dlg:separator{ text="Shurushki Settings" }
    if firsttime then
        dlg:label({text="FIRST TIME SETUP"})
        dlg:newrow()
        dlg:label({text="Thank you for using the plugin! Hope it comes in useful."})
        dlg:separator()
    end
    dlg:label{ text="Choose features you want to use" }
    dlg:newrow()
    dlg:label{ text="Please check out readme file for an explanation of features" }

    for _,prop in ipairs(commands) do
        local enabled = false
        for _,p in ipairs(prefs.commands) do
            if p.name == prop.name then
                enabled = true
                break
            end
        end

        dlg:check{ id=prop.name, label=prop.name, selected=enabled, text=prop.location }
    end

    dlg:button{id="enable_all", text="Enable All"}
    dlg:button{id="disable_all", text="Disable All"}
    dlg:button{id="ok", text="OK"}
    if not firsttime then
        dlg:button{id="cancel", text="Cancel"}
    end

    dlg:show()

    -- apply changes

    if dlg.data.cancel then
        return
    elseif dlg.data.disable_all then 
        prefs.commands = {}
    elseif dlg.data.enable_all then
        prefs.commands = all_commands()
    else
        prefs.commands = {}
        for _,prop in ipairs(commands) do 
            if dlg.data[prop.name] then
                table.insert(prefs.commands, prop)
            end
        end
    end

    -- be loud
    if not firsttime then
        app.alert("Menus will update the next time Aseprite starts.")
    end
end


function init(plugin)
    if not plugin.preferences.commands then 
        plugin.preferences.commands = all_commands()
        settings_dialog(plugin.preferences, true)
    end

    for _,props in ipairs(plugin.preferences.commands) do
        plugin:newCommand{
            id=props.name,
            title=props.name,
            group=props.group,
            onclick=run_script(props.name)
        }
    end

    plugin:newCommand{
        id="Shurushki",
        title="Shurushki",
        group="help_readme",
        onclick=function() settings_dialog(plugin.preferences) end
    }
end