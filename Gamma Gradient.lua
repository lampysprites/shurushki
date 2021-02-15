--[[ Generates a gamma-compensated gradient ]]

if #app.range.colors < 3 then
	app.alert("Please select a range of colors in the palette first")
end


-- simple lerp, gamma is calculated outside
local function mixcol(a,b,t)
	local gamma = 2.2
	local igamma = 1/gamma

	return (Color {
		red=((1-t)*a.red^gamma + t*b.red^gamma)^igamma,
		green=((1-t)*a.green^gamma + t*b.green^gamma)^igamma,
		blue=((1-t)*a.blue^gamma + t*b.blue^gamma)^igamma,
		alpha=((1-t)*a.alpha^gamma + t*b.alpha^gamma)^igamma,
	}).rgbaPixel
end


local palette = app.activeSprite.palettes[1]
local sel = app.range.colors
local colorFrom = palette:getColor(sel[1])
local colorTo = palette:getColor(sel[#sel])

app.transaction(function()
		for n,i in ipairs(sel) do
			palette:setColor(i, mixcol(colorFrom, colorTo, (n - 1) / (#sel - 1)))
		end
	end)