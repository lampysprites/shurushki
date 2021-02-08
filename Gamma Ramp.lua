-- [[ Generates a gamma-compensated gradient from primary to bg color in the first row of the image ]]
local img = app.activeImage

local function mixcol(t)
	local a,b = app.fgColor, app.bgColor
	return (Color {
		red= (1-t)*a.red + t*b.red,
		green= (1-t)*a.green + t*b.green,
		blue= (1-t)*a.blue + t*b.blue,
		alpha= (1-t)*a.alpha + t*b.alpha,
	}).rgbaPixel
end

for x=0,img.width-1 do
	img:drawPixel(x,0, mixcol((x/(img.width-1)) ^ 2.2))
end