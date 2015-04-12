local xml = require "xml"

local item = 0

local text = {}

local function extract(row)
	item = item + 1
	if item == 1 then
		return
	end
	local index = row[1][1]
	if index == nil then
		return
	end
	local v = {
		index = index[1],
		name = row[2][1][1],
		type = row[4][1][1],
	}
	if row[6][1] then
		v.desc = row[6][1][1]
	end
	table.insert(text, v)
end

local function addtag(s)
	return '>' .. s .. '</Data>'
end

local function replace(s, start, a , b)
	local from, to = string.find(s, addtag(a), start, true)
	return s:sub(1, from-1) .. addtag(b) .. s:sub(to+1) , from
end

local function main(filename)
	local f = assert(io.open(filename .. ".eng.xml"))
	local s = f:read "a"
	f:close()
	local t = xml.collect(s)
	local Workbook = t[2]
	local Worksheet
	for k,v in ipairs(Workbook) do
		if v.xml == "Worksheet" then
			Worksheet = v
			break
		end
	end
	local Table = Worksheet[1]
	for k,v in ipairs(Table) do
		if v.xml == "Row" then
			extract(v)
		end
	end
	for _,v in pairs(text) do
		local _, start = string.find(s, v.index)
		s, start = replace(s, start, v.name, "$"..v.index..".name")
		s, start = replace(s, start, v.type, "$"..v.index..".type")
		if v.desc then
			s, start = replace(s, start, v.desc, "$"..v.index..".desc")
		end
		local f = io.open(filename.."/"..v.index..".txt","wb")
		f:write(string.format([[
<index>%s</index>
<name>%s</name>
<cname></cname>
<type>%s</type>
<ctype></ctype>
<desc>%s</desc>
<cdesc></cdesc>
]], v.index, v.name, v.type, v.desc or ""
		))
		f:close()
	end
	local f = io.open(filename..".xml","wb")
	f:write(s)
	f:close()
end

main(...)
