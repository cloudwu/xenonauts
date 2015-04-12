local xml = require "xml"

local cache = {}

local function read(tag, root)
	if cache[tag] then
		return cache[tag]
	end
	local f = assert(io.open(root.."/"..tag..".txt"))
	local t = xml.collect(f:read"a")
	f:close()
	local r = {}
	for _,v in ipairs(t) do
		r[v.xml] = v[1]
	end
	cache[tag] = r
	return r
end

local function replace(filename)
	return function(s)
		local index, tag = s:match("(.*)%.(%w+)$")
		local trans = read(index, filename)
		local text = trans["c"..tag]
		if text == nil or text == "" then
			return trans[tag]
		else
			return text
		end
	end
end

local function main(filename)
	local f = assert(io.open(filename .. ".xml"))
	local s = f:read "a"
	f:close()
	local s = string.gsub(s, "%$([%w.]+)", replace(filename))
	local f = assert(io.open(filename .. ".chn.xml","wb"))
	f:write(s)
	f:close()
end

main(...)

