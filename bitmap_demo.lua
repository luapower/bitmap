local player = require'cplayer'
local glue = require'glue'
local stdio = require'stdio'
local ffi = require'ffi'
local bitmap = require'bitmap'

player.continuous_rendering = true

bitmap.dumpinfo()

local function load_bmp(filename)
	local bmp = stdio.readfile(filename)
	assert(ffi.string(bmp, 2) == 'BM')
	local function read(ctype, offset)
		return ffi.cast(ctype, bmp + offset)[0]
	end
	local data = bmp + read('uint32_t*', 0x0A)
	local w = read('int32_t*', 0x12)
	local h = read('int32_t*', 0x16)
	local stride = bitmap.aligned_stride(w * 3)
	local size = stride * h
	assert(size == ffi.sizeof(bmp) - (data - bmp))
	return {w = w, h = h, stride = stride, data = data, size = size,
		format = 'bgr8', bottom_up = true, bmp = bmp}
end

local function available(src_format, values)
	values = glue.index(values)
	local t = {}
	for k in pairs(values) do t[k] = false end
	for d in bitmap.conversions(src_format) do
		t[d] = values[d]
	end
	return t
end

local i = 0
function player:on_render(cr)

	i = (i + 1) % 10
	if i == 0 then jit.flush() end

	--apply dithering

	self.method = self:mbutton{id = 'method', x = 10, y = 100, w = 190, h = 24,
										values = {'fs', 'ordered', 'none'}, selected = self.method or 'none'}

	if self.method == 'fs' then
		local oldrbits = self.rbits
		self.rbits = self:slider{id = 'rbits', x = 10 , y = 130, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.rbits or 4, text = 'r bits'}
		if oldrbits ~= self.rbits then
			self.gbits = self.rbits
			self.bbits = self.rbits
			self.abits = self.rbits
		end
		self.gbits = self:slider{id = 'gbits', x = 10 , y = 160, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.gbits or 4, text = 'g bits'}
		self.bbits = self:slider{id = 'bbits', x = 10 , y = 190, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.bbits or 4, text = 'b bits'}
		self.abits = self:slider{id = 'abits', x = 10 , y = 220, w = 190, h = 24,
											i0 = 0, i1 = 8, step = 1, i = self.abits or 4, text = 'a bits'}

	elseif self.method == 'ordered' then
		self.map = self:mbutton{id = 'map', x = 10 , y = 130, w = 190, h = 24,
											values = {2, 3, 4, 8}, selected = self.map or 4}

	end

	--clip the low bits

	self.bits = self:slider{id = 'bits', x = 10,
										y = self.method == 'fs' and 250 or self.method == 'ordered' and 160 or 130,
										w = 190, h = 24, i0 = 0, i1 = 8, step = 1, i = self.bits or 8, text = 'out bits'}

	--convert to dest. format

	self.format = self.format or 'bgra8'

	local v1 = {
		'rgb8', 'bgr8', 'rgb16', 'bgr16',
		'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'rgbx16', 'bgrx16', 'xrgb16', 'xbgr16',
		'rgba8', 'bgra8', 'argb8', 'abgr8',
		'rgba16', 'bgra16', 'argb16', 'abgr16',
	}
	local e1 = available('bgr8', v1)
	local format1 = self:mbutton{id = 'format1', x = 10, y = 10, w = 990, h = 24,
						values = v1, enabled = e1, selected = self.format}
	local v2 = {
		'rgb565', 'rgb555', 'rgb444', 'rgba4444', 'rgba5551',
		'g1', 'g2', 'g4', 'g8', 'g16',
		'ga8', 'ag8', 'ga16', 'ag16',
		'cmyk8',
		'ycc8',
		'ycck8',
	}
	local e2 = available('bgr8', v2)
	local format2 = self:mbutton{id = 'format2', x = 10, y = 40, w = 990, h = 24,
						values = v2, enabled = e2, selected = self.format}
	self.format = format2 ~= self.format and format2 or format1

	--effects

	self.invert = self:togglebutton{id = 'invert', x = 10, y = 270, w = 90, h = 24, text = 'invert', selected = self.invert}
	self.grayscale = self:togglebutton{id = 'grayscale', x = 10, y = 300, w = 90, h = 24, text = 'grayscale', selected = self.grayscale}
	self.sharpen = self:togglebutton{id = 'sharpen', x = 10, y = 330, w = 90, h = 24, text = 'sharpen', selected = self.sharpen}
	if self.sharpen then
		self.sharpen_amount = self:slider{id = 'sharpen_amount', x = 10 , y = 360, w = 90, h = 24,
											i0 = -20, i1 = 20, step = 1, i = self.sharpen_amount or 4, text = 'amount'}

	end
	self.resize = self:togglebutton{id = 'resize', x = 10, y = 430, w = 90, h = 24, text = 'resize', selected = self.resize}
	if self.resize then
		self.resize_x = self:slider{id = 'resize_x', x = 10 , y = 460, w = 90, h = 24,
											i0 = 1, i1 = 2000, step = 1, i = self.resize_x or 400, text = 'resize_x'}
		self.resize_y = self:slider{id = 'resize_y', x = 10 , y = 490, w = 90, h = 24,
											i0 = 1, i1 = 2000, step = 1, i = self.resize_y or 200, text = 'resize_y'}
		self.resize_method = self:mbutton{id = 'resize_method', x = 10, y = 520, w = 90, h = 24,
											values = {'nearest', 'bilinear', 'bilinear1'}, selected = self.resize_method or 'nearest'}
	end

	--finally, perform the conversions and display up the images

	local cx, cy = 210, 100
	local function show(file)

		local bmp = load_bmp(file)

		if self.method == 'fs' then
			bitmap.dither.fs(bmp, self.rbits, self.gbits, self.bbits, self.abits)
		elseif self.method == 'ordered' then
			bitmap.dither.ordered(bmp, self.map)
		end

		--low-pass filter
		if self.bits < 8 then
			local c = 0xff-(2^(8-self.bits)-1)
			local m = (0xff / c)
			bitmap.paint(bmp, bmp, function(r,g,b,a)
				return
					bit.band(r,c) * m,
					bit.band(g,c) * m,
					bit.band(b,c) * m,
					bit.band(a,c) * m
			end)
		end

		if self.invert then
			bitmap.invert(bmp)
		end

		if self.grayscale then
			bitmap.grayscale(bmp)
		end

		if self.sharpen then
			local bmp0 = bmp
			bmp = bitmap.sharpen(bmp, self.sharpen_amount)
			bitmap.free(bmp0)
		end

		if self.resize then
			local bmp0 = bmp
			bmp = bitmap.resize[self.resize_method](bmp, bitmap.new(self.resize_x, self.resize_y, bmp.format))
			bitmap.free(bmp0)
		end

		if bmp.format ~= self.format then
			local bmp0 = bmp
			bmp = bitmap.copy(bmp, self.format, false, true)
			bitmap.free(bmp0)
		end

		self:image{x = cx, y = cy, image = bmp}
		bitmap.free(bmp)

		cx = cx + bmp.w + 10
	end

	show(glue.bin..'/media/bmp/bg.bmp')
	--show'media/bmp/parrot.bmp'
	--show'media/bmp/rgb_3bit.bmp'
	--show'media/bmp/rgb_24bit.bmp'
end

player:play()

