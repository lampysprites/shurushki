local dlg = Dialog()

-- define your vars/ functions here, and maybe add them to the help text below
-- using `local` keyword will make stuff inaccessible from formulas
minframe,maxframe = -1, -1 -- mostly internal use
t = -1
cnt = -1
len = -1
tlen = -1
sec = -1
abs,exp,log=math.abs,math.exp,math.log
sin = function(x) return math.sin(x * 180.0 / math.pi) end
cos = function(x) return math.cos(x * 180.0 / math.pi) end
-- normalize and scale
quad = function(height, t) return height * 4 * (t/(cnt-1)) * (t/(cnt-1) - 1) end
quadt = function(height) return height * 4 * (sec/tlen) * (sec/tlen - 1) end
push = function (v,a) 
	if a == nil then a = 0 end
	return v * t + a * t * t / 2
end
move = function(dist)
	return dist * t / cnt
end
movet = function(dist)
	return dist * sec / tlen
end

local seconds = function(t) 
	local time=0
	
	for i=minframe,minframe+t-1 do
		time = time + app.activeSprite.frames[i].duration
	end

	return time
end


local function go()
	minframe, maxframe = 999999, -1
	local fx, fy
	local wtf
	
	fx, wtf = load("return " .. dlg.data.fx)
	if wtf then
		app.alert(wtf)
		return
	end
	
	fy, wtf = load("return " .. dlg.data.fy)
	if wtf then
		app.alert(wtf)
		return
	end
		
	for _,cel in ipairs(app.range.cels) do
		minframe = math.min(minframe, cel.frameNumber)
		maxframe = math.max(maxframe, cel.frameNumber)
	end
	
	for _,cel in ipairs(app.range.cels) do
		local dx, dy
		
		t = cel.frameNumber - minframe
		sec = seconds(t)
		cnt = #app.range.frames
		len = maxframe - minframe + 1
		tlen = seconds(maxframe) - app.activeSprite.frames[maxframe].duration
		dx, dy = fx(), fy()
		
		cel.position = Point(cel.position.x + dx, cel.position.y + dy)
	end
end

local function help()
	local dlg = Dialog()
	dlg
		:separator{text="Functions"}
		:label{label="abs(x) cos(deg) sin(deg) exp(x) log(x)", text="math functions"}
		:label{label="push(speed, acc?)", text="move with given speed and acceleration (can be omited)"}
		:label{label="move(dist)", text="move with constant speed"}
		:label{label="movet(dist)", text="move with constant speed, accounting for frame durations"}
		:label{label="quad(height, x)", text="ballistic curve"}
		:label{label="quadt(height)", text="ballistic curve, accounting for frame durations"}
		:separator{text="Variables"}
		:label{label="t", text="frame# relative to the first selected cel, starting at 0"}
		:label{label="sec", text="time passed since the first selected cel in seconds"}
		:label{label="cnt", text="# of selected frames"}
		:label{label="len", text="# of frames from the first to the last of selected frames"}
		:label{label="tlen", text="time between beginnings of the first and the last selected frames"}
		:button{text="Close", focus=true, onclick=function() dlg:close() end}
		:show{wait=false}
end

dlg
	:separator{text="Move Cels"}
	:entry{id="fx",label="Move X = ",text="0",focus=true}
	:entry{id="fy", label="Move Y = ", text="0", focus=true}
	:button{text="Help", onclick=help}
	:button{text="Cancel", onclick=function() dlg:close() end}
	:button{text="OK", focus=true, onclick=function() app.transaction(go) dlg:close() end}
	:show()

