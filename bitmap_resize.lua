
--bitmap resampling.
--Written by Cosmin Apreutesei. Public domain.

local bitmap = require'bitmap'

bitmap.resize = {}

function bitmap.resize.nearest(src, dst)

	local src_getpixel = bitmap.pixel_interface(src)
	local _, dst_setpixel = bitmap.pixel_interface(dst)

	local tx = (src.w-1) / dst.w
	local ty = (src.h-1) / dst.h

	for y1 = 0, dst.h-1 do
		for x1 = 0, dst.w-1 do
			local x = math.ceil(tx * x1)
			local y = math.ceil(ty * y1)
			dst_setpixel(x1, y1, src_getpixel(x, y))
		end
	end

	return dst
end

local min, max = math.min, math.max
local function clamp(x, t0, t1)
	return min(max(x, t0), t1)
end

function bitmap.resize.bilinear(src, dst)

	local ctype1 = bitmap.colortype(src)
	local ctype2 = bitmap.colortype(dst)
	assert(ctype1 == ctype2, 'different colortypes')
	local n = #ctype1.channels

	local floor = math.floor
	local maxx, maxy = src.w-1, src.h-1

	local tx = src.w / dst.w
	local ty = src.h / dst.h

	for channel = 1,n do

		local src_get_chan = bitmap.channel_interface(src, channel)
		local _, dst_set_chan = bitmap.channel_interface(dst, channel)

		for y1 = 0, dst.h-1 do
			for x1 = 0, dst.w-1 do

				local x = floor(tx * x1)
				local y = floor(ty * y1)

				local dx = tx * x1 - x
				local dy = ty * y1 - y

				x = clamp(x, 0, maxx)
				y = clamp(y, 0, maxy)

				dst_set_chan(x1, y1,
					src_get_chan(x,   y  )*(1-dx)*(1-dy) +
					src_get_chan(x+1, y  )*dx*(1-dy) +
					src_get_chan(x,   y+1)*(1-dx)*dy +
					src_get_chan(x+1, y+1)*dx*dy)
			end
		end
	end

	return dst
end

function bitmap.resize.bilinear1(src, dst)

	local src_get = bitmap.pixel_interface(src)
	local _, dst_set = bitmap.pixel_interface(dst)

	local floor = math.floor
	local maxx, maxy = src.w-1, src.h-1

	local tx = src.w / dst.w
	local ty = src.h / dst.h

	--local ffi = require'ffi'
	--print('src', src.data, ffi.cast('char*', src.data) + src.size)
	--print('dst', dst.data, ffi.cast('char*', dst.data) + dst.size)

	for y1 = 0, dst.h-1 do
		for x1 = 0, dst.w-1 do

			local x = math.floor(tx * x1)
			local y = math.floor(ty * y1)

			local dx = tx * x1 - x
			local dy = ty * y1 - y

			x = clamp(x, 0, maxx)
			y = clamp(y, 0, maxy)

			local r1, g1, b1, a1 = src_get(x,   y  ); local f1 = (1-dx)*(1-dy)
			local r2, g2, b2, a2 = src_get(x+1, y  ); local f2 = dx*(1-dy)
			local r3, g3, b3, a3 = src_get(x,   y+1); local f3 = (1-dx)*dy
			local r4, g4, b4, a4 = src_get(x+1, y+1); local f4 = dx*dy

			--dst_set(x1, y1, 0xff, 0xff, 0xff, 0xff)
			--[[
			local _ = r1 * f1 + r2 * f2 + r3 * f3 + r4 * f4
			local _ = g1 * f1 + g2 * f2 + g3 * f3 + g4 * f4
			local _ = b1 * f1 + b2 * f2 + b3 * f3 + b4 * f4
			local _ = a1 * f1 + a2 * f2 + a3 * f3 + a4 * f4
			]]
			local r = clamp(r1 * f1 + r2 * f2 + r3 * f3 + r4 * f4, 0, 0xff)
			local g = clamp(g1 * f1 + g2 * f2 + g3 * f3 + g4 * f4, 0, 0xff)
			local b = clamp(b1 * f1 + b2 * f2 + b3 * f3 + b4 * f4, 0, 0xff)
			local a = clamp(a1 * f1 + a2 * f2 + a3 * f3 + a4 * f4, 0, 0xff)
			dst_set(x1, y1, r, g, b, a)
		end
	end

	return dst
end


if not ... then require'bitmap_demo' end

