-- currntly works only in RGB mode

--[[ CONFIG ]]
-- truncate the auto-generated layer name to this length
max_layer_name_len = 12

--[[ BITMAPFONT PRINTING FUNCTIONS ]]--

-- find the rectange containing the requested character, excluding markers
local function bmf_find_char(font, char)
    local goal  = 1 + string.byte(char) - string.byte("!")
    local marker = font:getPixel(0, 0)
    local x,charstart = 1, 1
    local currentchar = 0

    while x < font.width do
        while font:getPixel(x, 0) == marker do
            x = x + 1
        end
        charstart = x
        
        while font:getPixel(x, 0) ~= marker do
            x = x + 1
        end

        currentchar = currentchar + 1
        if currentchar == goal then
            return Rectangle(charstart, 0, x - charstart, font.height)
        end
    end

    return Rectangle()
end


-- calculate width of the given text
local function bmf_text_width(font, text)
    local width = 0

    for ch in string.gmatch(text, ".") do
        if ch == " " then
            width = width + wspace
        else
            local chr = bmf_find_char(font, ch)
            width = width + chr.width
        end
    end

    return width
end


-- copy font characters onto the `dest` image
local function bmf_print(font, dest, text, x, y, lspace, wspace)
    for ch in string.gmatch(text, ".") do
        if ch == " " then
            x = x + wspace
        else
            local chr = bmf_find_char(font, ch)
            for px in font:pixels(chr) do
                dest:drawPixel(x + px.x - chr.x, y + px.y - chr.y, px())
            end
            x = x + chr.width + lspace
        end
    end
end

--[[ SCRIPT BUSINESS ]]--


-- TODO use an original font
-- Road 6 is my original font, no attribution needed ~lampysprites
local fontfile = app.fs.joinPath(app.fs.userConfigPath, "extensions", "shurushki", "fonts", "road_6.png")
local lspace = 0
local wspace = 8 -- word spacing bc it's not in the font
local lineh = 1
local layer = nil
local lines = {""}

local font = nil
local layer = nil


function add_line() -- button handler
    lines = {}
    for k,v in pairs(dlg.data) do
        local num = string.match(k, "line(%d+)")
        if num then
            lines[tonumber(num)] = v
        end
    end

    table.insert(lines, "")

    refresh()
end


function remove_line() -- button handler
    lines = {}
    for k,v in pairs(dlg.data) do
        local num = string.match(k, "line(%d+)")
        if num then
            lines[tonumber(num)] = v
        end
    end

    table.remove(lines, #lines)
    refresh()
end


function print_text()
    font = Image{fromFile=fontfile}

    if not layer then
        layer = app.activeSprite:newLayer()
    end
    layer.name = string.sub(lines[1] or "Bitmap Text", 1, max_layer_name_len)

    lines = {}
    for k,v in pairs(dlg.data) do
        local num = string.match(k, "line(%d+)")
        if num then
            lines[tonumber(num)] = v
        end
    end

    local dest = app.activeSprite:newCel(layer, app.activeFrame or 1).image

    for i,line in ipairs(lines) do
        bmf_print(font, dest, line, 0, (i - 1) * (font.height + dlg.data.lineh), dlg.data.lspace, dlg.data.wspace)
    end
end


function cancel()
    if layer then
        app.activeSprite:deleteLayer(layer)
    end
    dlg:close()
    app.refresh() -- sometimes it doesn't update :(
end


function refresh()
    local rect = Rectangle(dlg.bounds)
    fontfile = dlg.data.fontfile
    lspace = dlg.data.lspace
    wspace = dlg.data.wspace
    lineh = dlg.data.lineh

    dlg:close()
    show_dialog(rect)
end


function show_dialog(bounds)
    dlg = Dialog()
    dlg:separator{text="Bitmapfont Text"}

    for i,l in ipairs(lines) do
        if i == 1 then 
            dlg:entry{ id="line"..i, label="Text", text=lines[i], focus=(i==#lines)}
        else
            dlg:entry{ id="line"..i, text=lines[i], focus=(i==#lines)}
        end
        dlg:newrow()
    end

    dlg:button{text="+ New Line", onclick=add_line}
    if #lines > 1 then 
        dlg:button{text="- Del Line", onclick=remove_line}
    end

    dlg:file{ id="fontfile", label="Font file", open=true, title="Choose font file", filename=fontfile}

    dlg:number{ id="lspace", label="Letter Spacing", text=tostring(lspace)}
    dlg:number{ id="wspace", label="Word Spacing", text=tostring(wspace)}
    dlg:number{ id="lineh", label="Line Spacing", text=tostring(lineh)}


    dlg:separator()
    dlg:button{text="Print", onclick=print_text}
    dlg:button{text="OK", onclick=function() print_text() dlg:close() end}
    dlg:button{text="Cancel", onclick=cancel}

    
    dlg:show() -- everything becomes hard when it's non-blocking
    if bounds then
        bounds.height = dlg.bounds.height
    else
        bounds = Rectangle(dlg.bounds)
        bounds.width = 256
    end
    dlg.bounds = bounds
end


if not app.activeSprite then
    app.alert("Please open the sprite first!")
else
    -- one transaction to undo everything at once
    app.transaction(function()
        show_dialog()
    end)
end