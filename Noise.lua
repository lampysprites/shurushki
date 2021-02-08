-- COPYPASTE https://github.com/kennethdamica/Diamond_Square_Noise
local Diamond_Square = {}

Diamond_Square.create = function(self,size)
	assert(math.floor(math.log(size-1)/math.log(2)) == math.log(size-1)/math.log(2), 
		"ERROR: Argument 'size' must be of the form 2^n + 1")
	local w = size
	local h = size
	local offset = w - 1
	local range = 128
	local modifier = 0.65
	local default = 128
	local min = 255
	local max = 0
	local min_temp, max_temp

	--define the grid
	local grid = {}
	for i = 0, w - 1 do
		grid[i] = {}
	end

	--set default values at the corners
	grid[0][0]=default
	grid[w-1][0]=default
	grid[0][h-1]=default
	grid[w-1][h-1]=default

	while offset > 1 do
		y = 0
		--diamond step
		while y < h - 1 do
			x = 0
			while x < w - 1 do
				--val set to average of four corners
				local val = (grid[x][y]+grid[x+offset][y]+grid[x][y+offset]+grid[x+offset][y+offset])/4 + math.random(-1*range,range)
				min_temp = math.min(min,val)
				max_temp = math.max(max,val)
				grid[x+offset/2][y+offset/2] = val
				x = x + offset
			end -- while x < w - 1
			y = y + offset
		end --while y < h - 1

		y = 0
		--square step
		while y < h do
			x = (y+(offset/2)) % offset
			while x < w do
				local val = 0

				if x == 0 then
					val = val + grid[(w-1)-(offset/2)][y]
				else
					val = val + grid[x-(offset/2)][y]
				end --if x==0
				if (x==(w-1)) then
					val = val + grid[(offset/2)][y]
				else
					val = val + grid[x+(offset/2)][y]
				end
				if (y==0) then
					val = val + grid[x][(h-1)-(offset/2)]
				else
					val = val + grid[x][y-(offset/2)]
				end
				if (y==(h-1)) then
					val = val + grid[x][(offset/2)]
				else
					val = val + grid[x][y+(offset/2)]
				end
				val = val/4 + math.random(-1*range,range)
				min_temp = math.min(min,val)
				max_temp = math.max(max,val)
				grid[x][y] = val
				x = x + offset
			end 
			y = y + offset/2
		end
		
		range = range * modifier
		offset = offset/2

	end --while offset > 1
	
	return grid

end --create

-- END COPYPASTE

function diamondsquare()
    -- generate noise
    local maxsize = math.max(app.activeSprite.width, app.activeSprite.height)
    local potsize = 2 ^ math.ceil(math.log(maxsize) / math.log(2))
    local noise = Diamond_Square:create(potsize + 1) -- arg must be power of two + 1


    -- render
    local buf = app.activeImage:clone()

    for y, row in ipairs(noise) do
        for x, strength in ipairs(row) do
            val = math.floor(strength)
            if val > 255 then val = 255 end
            if val <0 then val = 0 end

            buf:drawPixel(x - 1, y - 1, Color{ gray=val, alpha=255 })
        end
    end

    app.activeImage:drawImage(buf)
    app.refresh()
end

dlg = Dialog()
    :button{ id="go", text="Generate", label="Diamond Square", onclick=diamondsquare }
    :button{ id="close", text="Close", onclick=function() dlg:close() end }
    :show{wait=false}

