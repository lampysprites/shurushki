--[[ Change duration of multiple frames proportionally, or with a linear function ]]
local dlg = Dialog()

local function go()
	local scale = tonumber(load("return " .. dlg.data.scale)())
	local add = tonumber(load("return " .. dlg.data.add)())
	local frames = dlg.data.onlyselected and app.range.frames or app.activeSprite.frames
	
	if scale == nil or add == nil then
		app.alert("Please enter a number or an expression")
		return
	end
	
	for _,frame in ipairs(frames) do
		frame.duration = frame.duration*scale + add/1000
	end
end

dlg
	:separator{text="Scale Time"}
	:entry{id="scale",label="Scale",text="1",focus=true}
	:entry{id="add",label="Add",text="0"}
	:check{id="onlyselected",text="Only Selected",selected=true}
	:button{text="Cancel", onclick=function() dlg:close() end}
	:button{text="OK", focus=true, onclick=function() app.transaction(go) dlg:close() end}
	:show()