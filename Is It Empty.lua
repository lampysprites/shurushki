local is_empty = (#app.activeLayer.cels == 0)

local dlg = Dialog()
    :separator{ text="Is Layer Empty?" }
    :label{ label = is_empty and "It's empty" or "It's not empty" }
if is_empty then
    dlg:button { id="delete", text="Delete" }
else
    dlg:button { id="show", text="Go To Cel" }
end
dlg:button{ text="Close" }
    :show()

if dlg.data.delete then
    app.command.RemoveLayer()
elseif dlg.data.show then
    app.activeFrame = app.activeLayer.cels[1].frame
end