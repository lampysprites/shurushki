function run_script(f) 
    return function()
        dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "shurushki", f))
    end
end

function init(plugin)
    plugin:newCommand{
        id="Bitmap Text",
        title="Bitmap Text",
        group="edit_fill",
        onclick=run_script("Bitmap Text.lua")
    }

    plugin:newCommand{
        id="Export Atlas",
        title="Export Atlas",
        group="file_export",
        onclick=run_script("Export Atlas.lua")
    }

    plugin:newCommand{
        id="Frame Pattern",
        title="Frame Pattern",
        group="select_simple",
        onclick=run_script("Pattern Select Frames.lua")
    }

    plugin:newCommand{
        id="Gamma Ramp",
        title="Gamma Ramp",
        group="edit_fill",
        onclick=run_script("Gamma Ramp.lua")
    }

    plugin:newCommand{
        id="Highlight Cels",
        title="Highlight Cels...",
        group="view_animation_helpers",
        onclick=run_script("Highlight Cels.lua")
    }

    plugin:newCommand{
        id="Link Active Cel",
        title="Link Active",
        group="cel_popup_links",
        onclick=run_script("Link Active Cel.lua")
    }

    plugin:newCommand{
        id="Link Cel To All Frames",
        title="Link To All Frames",
        group="cel_popup_links",
        onclick=run_script("Link Cel To All Frames.lua")
    }

    plugin:newCommand{
        id="Move Cels",
        title="Move Cels...",
        group="edit_transform",
        onclick=run_script("Move Cels.lua")
    }

    plugin:newCommand{
        id="Splice Animation",
        title="Splice Animation",
        group="file_export",
        onclick=run_script("Splice Animation.lua")
    }

    plugin:newCommand{
        id="Time Stretch",
        title="Time Stretch",
        group="cel_frames",
        onclick=run_script("Time Stretch.lua")
    }
end