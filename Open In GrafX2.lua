--[[ CONFIG  ]]
local editor = "C:\\Program Files\\GrafX2\\bin\\grafx2-win32.exe"

--[[ SCRIPT ]]
local original = app.activeSprite
local img = Image(original.spec)
local temp_file = app.fs.joinPath(app.fs.tempPath, "shki_temp.gif")

img:drawImage(app.activeImage, app.activeCel.position)
img:saveAs(temp_file)

os.execute(string.format('start /wait "" "%s" "%s"', editor, temp_file))
-- the script continues when the editor closes

local edited = Sprite{fromFile=temp_file}
-- opening a new file changed the activesprite, which will mess up the transaction img time
app.activeSprite = original

app.transaction(function()
    if original.colorMode == ColorMode.RGB then
        local idx

        for px in edited.cels[1].image:pixels() do
            idx = px()

            if idx == edited.transparentColor then
                img:drawPixel(px.x, px.y, 0)
            else
                img:drawPixel(px.x, px.y, edited.palettes[1]:getColor(idx))
            end
        end
            app.activeCel.position = Point()
            app.activeCel.image = img
        else
            error("lampy you lazy piece of shit")
        end
end)

edited:close()