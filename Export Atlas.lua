--[[ CONFIG SETTINGS ]]

-- if the script complains about python install, and you have python3 installed,
-- change this to to the python executable
python_executable = "python"
-- the starting sheet size to try by an auto option
starting_size = 64
-- list of texsize options in the ui. Technically, doesn't have to be 2**n.
-- format: {{"BUTTONLABEL", "VALUE"}, ... }
size_options = {{"auto","0"}, {"256","256"}, {"512","512"}, {"1k","1024"},
                      {"2k","2048"}, {"4k","4096"}, {"8k","8192"}, {"16k", "16384"}}

--[[ config section ends here ]]

--[[ UTIL ]]

-- for ase objects (e.g Image) need to compare keys as obj1 == obj2 with an "=="; table[obj] might miss the existing key
function find_by_key(map, key)
    for k, v in pairs(map) do
        if k == key then
            return v
        end
    end 
    return nil
end


-- TODO delete this
function tmp_file(fname, text)
    local fname = app.fs.joinPath(app.fs.tempPath, fname)
    local hnd = io.open(fname, "w")
    if hnd == nil then
        app.alert("Cannot open temp file for writing: " .. fname)
        return nil
    end
    if hnd:write(text) then
        hnd:close()
        return app.fs.joinPath(app.fs.tempPath, fname)
    end
end


--[[ PYTHON RELATED STUFF
        this script will write a python file and use it to calculate the atlas packing
    not the cleanest way but the problem is not easy, and I haven't found a good solution in pure lua ]]
packer_source=[[
from rectpack import newPacker
import sys

pagecount = int(sys.argv[1])
texsize = int(sys.argv[2])
rects = sys.argv[3]

packer = newPacker(rotation=False)
packer.add_bin(texsize, texsize)

vid = 0
for pair in rects.split(","):
    (width, height) = pair.split("x")
    packer.add_rect(int(width), int(height), vid)
    vid += 1

# do work
packer.pack()

if len(packer) == 0:
    sys.stdout.write("toosmall")
else:
    # whyy does it have to change the order, let's restore it same as input
    packed_rects = [(rect.x, rect.y, rect.rid, rect.width, rect.height) for rect in packer[0] ] #the double bracket will confuse Lua
    packed_rects = sorted(packed_rects, key=lambda r: r[2])

    if len(packed_rects) < vid:
        sys.stdout.write("toosmall")
    else:
        # pass back as csv again via stdout
        packed_str = ",".join([f"{a}:{b}*{w}*{h}" for (a,b,r,w,h) in packed_rects])
        sys.stdout.write(packed_str)
]]


function check_python_installed()
    -- check for python itself
    if not os.execute(python_executable .. ' -c ""') then
        app.alert('Cannot detect python executable at "' .. python_executable .. '"\n' ..
            'Please make sure python3 is installed, or edit its location in the script file')
        return false
    elseif not os.execute(python_executable .. ' -c "import rectpack"') then
        app.alert('Rectpack library not found. Please install it\n'..
            ' e.g. by running "python -m pip install rectpack" in command line')
        return false
    end
    return true
end


-- copy python code to a temp file
function deploy_packer_script()
    local fname = app.fs.joinPath(app.fs.tempPath, "atlase_packer.py")
    local hnd = io.open(fname, "w")
    if hnd == nil then
        app.alert("Cannot open temp file for writing: " .. fname)
        return nil
    end
    if hnd:write(packer_source) then
        hnd:close()
        return fname
    end
end

--[[ PACKING LOGIC
        executed from the dialog ui. It can be reused in a custom script, if you're looking for a CLI option]]
-- add the sprite's cels to packing data

function prepare_packing(bounds, bounds_map, sprite)
    local i = #bounds + 1
    for _,cel in ipairs(sprite.cels) do
        local image = cel.image
        -- skip linked cels - they have the same image as one of the previous cels
        -- so the map has an entry for them

        if find_by_key(bounds_map, image) == nil then
            bounds[i] = {w=cel.bounds.width, h=cel.bounds.height, cel=cel}
            bounds_map[image] = i
            i = i + 1
        end
    end
end


-- transform all entries in bounds array from {w, h, ...rest} into {w, h, x, y, page, ...rest}
--      where x and y are the coordinates in the texture page
function run_packer(bounds, pagecount, texsize)
    -- flatten data to pass it to the packing script as one huge csv
    local bounds_str = {}
    for i,b in ipairs(bounds) do
        bounds_str[i] = bounds[i].w .. "x" .. bounds[i].h
    end
    bounds_str = table.concat(bounds_str, ",")

    -- past to the packer
    local cmd = string.format("python %s %d %d %s", packer_script, pagecount, texsize, bounds_str)

    hnd = io.popen(cmd)
    tmp_file("celsheet.out", cmd)
    packed_str = hnd:read("*a")
    hnd:close()

    if packed_str == "" then
        return "script error"
    elseif packed_str == "toosmall" then
        return "too small"
    else
        local i = 1
        for x,y in string.gmatch(packed_str, "(%d+):(%d+),?") do
            bounds[i].x = x
            bounds[i].y = y
            bounds[i].page = 1 -- TODO
            i = i + 1
        end
        return "success"
    end
end


-- pack into the smallest possible single page
function packer_auto_size(bounds)
    local size = starting_size

    while true do
        local result = run_packer(bounds, 1, size)

        if result == "success" then
            return size
        elseif result == "too small" then
            size = 2 * size
        else
            return 0
        end
    end
end


-- pack into pages of the same size
function packer_auto_pages(bounds, texsize)
    local pages = 1

    while true do
        local result = run_packer(bounds, pages, texsize)

        if result == "success" then
            return pages
        elseif result == "too small" then
            pages = 1 + pages
        else
            return 0
        end
    end
end


-- generate packed Image(s). returns an array
function pack_textures(sprites, texsize, pages)
    local bounds = {}
    local image_to_bounds_map = {}
    local result

    for _,sprite in ipairs(sprites) do
        prepare_packing(bounds, image_to_bounds_map, sprite)
    end
    if texsize == 0 then
        result = packer_auto_size(bounds)
        texsize = result
    elseif pages == 0 then
        result = packer_auto_pages(bounds, texsize)
        pages = result
    else
        result = run_packer(bounds, pages, texsize)
        if result == "too small" then
            app.alert("Pack failed: texture size is too low")
            return
        elseif result ~= "success" then
            result = 0
        end
    end

    if result == 0 then
        app.alert("Pack failed: packing script error :(")
        return
    end

    local texpages = {}

    for pn=1,pages do
        local img = Image(texsize, texsize)
        for i,bb in ipairs(bounds) do
            if bb.page == pn then
                img:drawImage(bb.cel.image, bb.x, bb.y)
            end
        end
        table.insert(texpages, img)
    end

    return texpages, texsize, bounds, image_to_bounds_map
end


--[[ EXPORT RECORD 
        put together data for exporting]]

-- number layers linearly to use it as a global id later
-- second arg is function's internal use
function flatten_layers(layers, acc)
    if acc == nil then 
        acc = {} 
    end

    for _,layer in ipairs(layers) do
        table.insert(acc, layer)
        if layer.layers then
            flatten_layers(layer.layers, acc)
        end
    end

    return acc
end


-- get an id for a layer
function layer_glob_index(layers_flattened, layer)
    for i=1,#layers_flattened do
        if layers_flattened[i] == layer then
            return i
        end
    end
    return 0
end


function json_layers(sprite)
    local layers_flattened = flatten_layers(sprite.layers)
    local entries = {}

    local add_layer_entry 
    add_layer_entry = function (layer, group)
        local id = layer_glob_index(layers_flattened, layer)
    
        local entry = table.concat({
            '{"id": ', id, ',',
            '"name": "', layer.name, '",',
            '"group": ', layer.isGroup and 'true' or 'false', ',',
            '"attached": ', group == nil and  'null' or group - 1, ',', 
            '"data": "', layer.data, '"}'
        }, "")
        table.insert(entries, entry)
    
        if layer.isGroup and #layer.layers >= 1 then 
            for _,l in ipairs(layer.layers) do
                add_layer_entry(l, id)
            end
        end
    end

    for _,l in ipairs(sprite.layers) do
        add_layer_entry(l)
    end

    return "[" .. table.concat(entries, ",") .. "]", layers_flattened
end


-- record cel data
function json_cels(sprite, bounds, image_to_bounds_map, layers_flattened)
    local entries = {}

    for i,cel in ipairs(sprite.cels) do
        local bb = bounds[find_by_key(image_to_bounds_map, cel.image)]
        local page = 1 -- TODO bb.page
        
        local entry = table.concat({
                '{"layer": ', layer_glob_index(layers_flattened, cel.layer) - 1, ',', -- switch to cultcargo arrays
                '"frame": ', cel.frameNumber, ',',
                '"duration" :', math.floor(cel.frame.duration * 1000) ,',',
                '"page": ', page - 1, ',', -- switch to cultcargo arrays
                '"x": ', cel.position.x, ',',
                '"y": ', cel.position.y, ',',
                '"u": ', bb.x, ',',
                '"v": ', bb.y, ',',
                '"w": ', bb.w, ',',
                '"h": ', bb.h, ',',
                '"data": "', cel.data, '"}'
            }, "")
        entries[i] = entry
    end

    return "[" .. table.concat(entries, ",") .. "]"
end


function json_tags(sprite)
    entries = {}
    for i,tag in ipairs(sprite.tags) do
        local dir = '"forward"'

        if tag.aniDir == 1 then
            dir = '"reverse"'
        elseif tag.aniDir == 2 then
            dir = '"pingpong"'
        end

        local entry = table.concat({
            '{"from": ', tag.fromFrame.frameNumber, ',',
            '"to": ', tag.toFrame.frameNumber, ',',
            '"name": "', tag.name, '",',
            '"dir": ', dir, '}'
        }, "")
        
        entries[i] = entry
    end

    return "[" .. table.concat(entries, ",") .. "]"
end


--[[ UI DIALOG BOX ]]
dlg = {} -- Dialog() later
sprites = {} -- user's selection of which sprites to export
preview_sprites = {} -- sprites opened for preview
temp_opened_sprites = {} -- to reopen the sprites included in exporting

function json_export(size, pages)
    local textures = {}
    for i,page in ipairs(pages) do 
        textures[i] = app.fs.fileName(page)
    end
    textures = table.concat(textures, '","')

    local sprite_names = {}
    for i,s in ipairs(sprites) do
        sprite_names[i] = s.filename or ""
    end
    sprite_names = table.concat(sprite_names, '","')
    sprite_names = string.gsub(sprite_names, '\\', '\\\\')

    return table.concat({
        '{"sprites": ["', sprite_names ,'"],',
        '"pages": ', #pages, ',',
        '"padding": 0,', -- TODO
        '"textures": ["', textures, '"],',
        '"size": ', size, '}'
    }, "")
end


function ensure_sprites_open()
    -- clean up closed sprites (they might still work but not sure?)
    for i=#sprites,1,-1 do
        local open = false
        for _,spr in ipairs(app.sprites) do 
            if spr.filename == sprites[i].filename then
                open = true
                break
            end
        end

        if not open then
            local fn = sprites[i].filename
            sprites[i] = app.open(fn)
            if sprites[i] == nil then
                -- TODO possibly stop exporting
                local press = app.alert{text="Sprite can not be opened, or no longer exists: \nDo you want to and export remaining sprites?" .. fn, buttons={"Export", "Cancel"}}
                if press == 2 then
                    return false 
                end

                table.remove(sprites,i)
            else
                table.insert(temp_opened_sprites, sprites[i])
            end
        end
    end

    return true
end


function preview() -- button callback
    if #sprites == 0 then 
        app.alert("No sprites chosen!") 
        return
    end

    for _,spr in ipairs(preview_sprites) do
        spr:close()
    end
    preview_sprites = {}

    if not ensure_sprites_open() then
        return 
    end

    local pages = pack_textures(sprites, dlg.data.texsize, 1--[[dlg.data.pages]])
    if pages ~= nil then 
        for i,tex in ipairs(pages) do
            local texspr = Sprite(tex.width, tex.height)
            texspr.cels[1].image = tex
            table.insert(preview_sprites, texspr)
        end
    end

    for _,spr in ipairs(temp_opened_sprites) do
        spr:close()
    end
    temp_opened_sprites = {}
end


function cancel() -- button callback
    for _,spr in ipairs(preview_sprites) do
        spr:close()
    end

    for _,spr in ipairs(temp_opened_sprites) do
        spr:close()
    end

    dlg:close()
end


function export() -- button callback
    if #sprites == 0 then 
        app.alert("No sprites chosen!") 
        return
    end

    if not ensure_sprites_open() then
        return 
    end

    local hnd = io.open(dlg.data.outfile, "w")
    -- full path minus the extension, so that suffixes could be added
    local cname = app.fs.joinPath(app.fs.filePath(dlg.data.outfile), app.fs.fileTitle(dlg.data.outfile))

    if hnd == nil then
        app.alert("Cannot open file for writing: " .. cname)
        return
    end
    
    local pages, texsize, bounds, image_to_bounds_map = pack_textures(sprites, dlg.data.texsize, 1--[[dlg.data.pages]])
    if pages ~= nil then 
        for i,tex in ipairs(pages) do
            local texname = string.format("%s_%03d.png", cname, i)
            -- /path/to/myfile_001.png etc..
            tex:saveAs(texname)
            -- replace the page with its location bc lazy
            pages[i] = texname
        end
    end

    local json_sprites = {}
    for _,sprite in ipairs(sprites) do
        local layer_entries, layers_flattened = json_layers(sprite)
        local tag_entries = json_tags(sprite)
        local cel_entries = json_cels(sprite, bounds, image_to_bounds_map, layers_flattened)
        local short_name = app.fs.fileTitle(sprite.filename)
        local json_sprite = string.format('{"name": "%s", "length": %d, "w": %d, "h": %d, "layers":%s,"tags":%s,"frames":%s}',
            short_name, #sprite.frames, sprite.width, sprite.height, layer_entries, tag_entries, cel_entries, export_settings)

        table.insert(json_sprites, json_sprite)
    end
    
    local export_settings = json_export(texsize, pages)
    local json_all = string.format('{"export_settings": %s, "sprites": [%s]}', export_settings, table.concat(json_sprites, ","))

    if not hnd:write(json_all) then
        app.alert("Error writing file: " .. dlg.data.outfile)
    end

    hnd:close()
    cancel() -- it just does the cleanup
end


function show_dialog(bounds)
    dlg = Dialog()
    dlg:separator{text="Atlaseprite export"}
    dlg:button{ label="Sprites", text="+ Add Current", onclick=function() add_sprite(app.activeSprite) end }
    dlg:button{ text="+ Add Open", onclick=add_open }
    for i,sprite in ipairs(sprites) do
        dlg:button { label="", text = "- " .. sprite.filename, onclick=remove_sprite_f() }
    end
    -- TODO
    -- dlg:number{ id="pages", label="Pages", text="1"}
    dlg:number{ id="texsize", label="Page Size", text="0"}
    dlg:newrow()
    for i,text_val in pairs(size_options) do
        dlg:button{text=text_val[1], onclick=change_texsize_f(text_val[2])}
    end
    -- dlg:number{ id="pad", label="Padding", text="0"}

    dlg:file{ label="Output File", id="outfile", save=true, filename="", filetypes={"json"} }

    dlg:newrow()
    dlg:separator()
    -- TODO
    -- dlg:check{id="savesettings", text="Remember Settings"}
    dlg:button{text="Preview", onclick=preview}
    dlg:button{text="Export", onclick=export}
    dlg:button{text="Re-export", onclick=function() end}
    dlg:button{text="Cancel", onclick=cancel}

    if bounds then
        dlg:show{ wait=false }
        bounds.width = dlg.bounds.width
        bounds.height = dlg.bounds.height
        dlg.bounds = bounds
    else
        dlg:show{ wait=false }
    end
end


function change_texsize_f(val)
    return function()
        dlg:modify{id="texsize", text=val}
    end
end


function add_sprite(sprite)
    sprite = sprite or app.activeSprite

    if not sprite then
        return
    end

    -- let's hope localization doesn't mess up this bit - _ -
    if string.sub(sprite.filename, 1, 6) == "Sprite" then 
        return 
    end

    for i=1,#sprites do
        if sprites[i].filename == sprite.filename then
            return
        end
    end
    table.insert(sprites, sprite)
    refresh()
end


function add_open() 
    for _,sprite in ipairs(app.sprites) do
        add_sprite(sprite)
    end
end


function remove_sprite_f(idx)
    return function()
        table.remove(sprites, idx)
        refresh()
    end
end


function refresh()
    local rect = Rectangle(dlg.bounds)
    dlg:close()
    show_dialog(rect)
end

-- [[ ENTRY MAIN ]]

if check_python_installed() and app.isUIAvailable then
    packer_script = deploy_packer_script()
    if packer_script then
        show_dialog()
    end
end