--go@ luajit -e io.stdout:setvbuf'no' -jv *
local bitmap = require'bitmap'
local glue = require'glue'
require'unit'

bitmap.dumpinfo()
print()

for src_format in glue.sortedpairs(bitmap.formats) do

	print(string.format('%-6s %-4s %-10s %-10s %6s      %-10s',
			'time', '', 'src', 'dst', 'size', 'stride'))

	jit.flush()
	for dst_format in bitmap.conversions(src_format) do
		local src = bitmap.new(1921, 1081, src_format)
		local dst = bitmap.new(1921, 1081, dst_format, 'bottom_up', 'aligned_stride')

		timediff()
		bitmap.paint(src, dst)

		local flag = src_format == dst_format and '*' or ''
		print(string.format('%-6.4f %-4s %-10s %-10s %6.2f MB   %-10s',
				timediff(), flag, src.format, dst.format, src.size / 1024 / 1024, src.stride))
	end

end

