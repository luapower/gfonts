
--google fonts font selector.
--Written by Cosmin Apreutesei. Public Domain.

--Requires: git clone https://github.com/google/fonts media/fonts/gfonts.

local fs = require'fs'
local glue = require'glue'
local pp = require'pp'

local gfonts = {}

gfonts.root_dir = 'media/fonts/gfonts'

local function path(dir, file)
	return (dir or gfonts.root_dir) .. (file and '/' .. file or '')
end

local function parse_metadata_file(dir, file, fonts)
	file = file or 'METADATA.pb'
	fonts = fonts or {}
	local font
	for s in io.lines(path(dir, file)) do
		if s:find'^fonts {' then
			assert(not font)
			font = {}
		elseif s:find'^}' then
			assert(font)
			local name = font.name:lower()
			local fname = font.full_name:lower()
			fonts[name] = fonts[name] or {}
			fonts[fname] = fonts[fname] or {}
			local t = {
				path = path(dir, font.filename),
				style = font.style:lower(),
				weight = font.weight,
			}
			table.insert(fonts[name], t)
			table.insert(fonts[fname], t)
			font = nil
		elseif font then
			local k,v = assert(s:match'^(.-):(.*)$')
			k = glue.trim(k)
			v = glue.trim(v)
			if v:find'^"' then
				v = assert(v:match'^"(.-)"$')
			else
				v = assert(tonumber(v))
			end
			font[k] = v
		end
	end
	return fonts
end

local function parse_metadata_dir(dir, dt)
	dir = path(dir)
	dt = dt or {}
	for name, d in fs.dir(dir) do
		if d:is'dir' then
			parse_metadata_dir(path(dir, name), dt)
		elseif name == 'METADATA.pb' then
			parse_metadata_file(dir, name, dt)
		end
	end
	return dt
end

local fonts
function get_fonts()
	if not fonts then
		local mcache = path(nil, 'metadata.cache')
		if glue.canopen(mcache) then
			fonts = loadfile(mcache)()
		else
			fonts = parse_metadata_dir()
			pp.save(mcache, fonts)
		end
	end
	return fonts
end

function gfonts.font_file(name, weight, style)
	assert(name)
	weight = weight or 400
	style = style or 'normal'
	local t = get_fonts()[name]
	if not t then return end
	for i,t in ipairs(t) do
		if t.weight == weight and t.style == style then
			return t.path
		end
	end
end

if not ... then
	print(gfonts.font_file('open sans', 400, 'italic'))
end

return gfonts
