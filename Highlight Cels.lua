--[[
	Colorize timeline cels based on duration, or from selection.
	
	How to install:
		1. In Aseprite, open `File > Scripts > Open Scripts Folder`. In english locale it can be done by pressing `Alt+F, P, O` in succession
		2. Copy this file into the opened folder.
		   To save file from github, press "Raw" button above and hit Ctrl+S - don't copy-paste from the web page!
		3. Restart Aseprite
		4. (optional) Add keyboard shotcut by opening `Edit > Keyboard Shortcuts` (EN: `Alt+E, K`). Type the script name into the search box.
		   There's no difference between registering a shortcut for a command or a menu item AFAIK.
	
	author: twitter.com/librorumque
	workflow suggestions: twitter.com/swonqi
]]

--[[
  The MIT License (MIT)
  Copyright © 2019 librorumque
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

if app.activeSprite == nil then
	app.alert("Please open a sprite first")
	return
end

-- Default settings
local target = app.range.isEmpty and "duration" or "selection"
local targetduration = app.activeFrame.duration
local color = app.fgColor
local onlyactivelayer = false
local excludelinked = false


-- Find all frame durations used in the file
-- Returns a numbered table of unique values in milliseconds
local function getdurations()
	local set={}
	local t={}
	
	for i,frame in ipairs(app.activeSprite.frames) do
		set[frame.duration]=true
	end
	
	for elt in pairs(set) do
		t[#t+1]=elt
	end
	
	table.sort(t, function(a,b) return a<b end)
	
	for i=1,#t do
		t[i] = math.floor(1000*t[i]) .. "ms"
	end
		
	return t
end


-- Returns a numbered table of cels with given duration
local function findcelssbyduration(t,onlyactivelayer)
	local fs,cs={},{}
	
	for n,frame in ipairs(app.activeSprite.frames) do
		if math.floor(frame.duration*1000)==t then
			fs[n]=true
		end
	end
	
	for _,cel in ipairs(app.activeSprite.cels) do
		if fs[cel.frameNumber] and (not onlyactivelayer or cel.layer == app.activeLayer) then
			cs[#cs+1]=cel
		end
	end
	
	return cs
end


-- I'm not completely sure why cels with the same image share color, but that's how it works atm
-- returns false if the cel is linked to another one, with different duration; true otherwise
local function consistentduration(cel)
	for _,another in ipairs(app.activeSprite.cels) do
		if another.image==cel.image and another ~= cel 
				and another.frame.duration ~= cel.frame.duration then
			return false
		end
	end
	
	return true
end


-- returns false if the cel is linked to an unselected one; true otherwise
local function allselected(cel)
	-- works by counting linked cels inside selection and generally
	local selected,total = 0,0
	
	for _,another in ipairs(app.range.cels) do
		if another.image==cel.image then
			selected = selected + 1
		end
	end
	
	for _,another in ipairs(app.activeSprite.cels) do
		if another.image==cel.image then
			total = total + 1
			if total > selected then
				return false
			end
		end
	end
	
	return true
end


-- returns elements of a numbered table, for which the given function is true
local function filtertable(t, predicate)
	local result = {}
	
	for _,el in ipairs(t) do
		if predicate(el) then
			result[#result+1] = el
		end
	end
	
	return result
end


local function hlcels(cels, color)
	app.transaction(function()
			for _,cel in ipairs(cels) do
				cel.color = color
			end
		end)
	
	app.refresh()
end


local function dialog(x,y) -- re-create dialog to show diff widgets in diff modes
  local dlg = Dialog()
	
	local refreshdialog = function()
		dlg:close()
		dialog(dlg.bounds.x, dlg.bounds.y)
	end
	
	local apply = function()
			local cels
			
			if app.activeSprite == nil then
				app.alert("No sprite open")
				return
			end
			
			if target=="selection" then
				cels = app.range.cels
				
				if excludelinked then
					cels = filtertable(cels, allselected)
				end
			else
				local t=tonumber(string.sub(dlg.data.duration, 1, -3))
				cels = findcelssbyduration(t, onlyactivelayer)
				
				if excludelinked then
					cels = filtertable(cels, consistentduration)
				end
			end
			
			hlcels(cels, dlg.data.color)
		end

	-- messy UI code and nothing else
  dlg
		:label{label="--- Highlight Cels ---"}
		:color{id="color", label="Color", color=color}
		:button{text="From active", onclick=function() color=app.activeCel.color refreshdialog() end}
		:button{text="Clear", onclick=function() color=nil refreshdialog() end}
		:radio{label="Target", text="Selected", selected=(target == "selection"),
			onclick=function() target="selection" refreshdialog() end}
		:radio{label="", text="By duration", selected=(target == "duration"),
			onclick=function() target="duration" refreshdialog() end}

  if target == "duration" and app.activeSprite then
		local options=getdurations()
		
    dlg
			:combobox{id="duration", label="Duration", option=options[1], options=options}
			:check{label="Only active layer", selected=onlyactivelayer,
				onclick=function() onlyactivelayer = not onlyactivelayer end}
  end
	
	dlg
		:check{label="Exclude linked to unmatching", selected=excludelinked,
			onclick=function() excludelinked = not excludelinked end}
		:button{text="Refresh", onclick=function() refreshdialog() end}
		:button{text="Close", onclick=function() dlg:close() end}
		:button{text="Apply", focus=true, onclick=apply}
		:button{text="OK", onclick=function() apply() dlg:close() end}

  dlg:show{wait=false}
	
	if x and y then -- keep position
		dlg.bounds = Rectangle(x,y,dlg.bounds.width, dlg.bounds.height)
	end
end

dialog()
