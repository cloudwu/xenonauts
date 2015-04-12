-- A modify version from http://lua-users.org/wiki/LuaXml

local xml = {}

local function parseargs(s,arg)
  string.gsub(s, "([%-%w:]+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end

function xml.collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if text ~= "" then
      if top["xml:space"] == "preserve" then
          table.insert(top, text)
      else
        text = text:match "^%s*(.*)%s*$"
        if text ~= "" then
            table.insert(top, text)
        end
      end
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, parseargs(xarg, {xml=label}))
    elseif c == "" then   -- start tag
      top = parseargs(xarg, { xml=label })
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.xml ~= label then
        error("trying to close "..toclose.xml.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

local function seri_args(tbl)
	local tmp = { " " }
	for k,v in pairs(tbl) do
		if type(k) == "string" and k~="xml" then
			table.insert(tmp, string.format('%s="%s"',k,v))
		end
	end
	if #tmp == 1 then
		return ""
	else
		return table.concat(tmp)
	end
end

local function seri(root)
	if type(root) == "string" then
		return root
	end
	if root[1] == nil then
		return string.format("<%s%s/>", root.xml, seri_args(root))
	else
		local tmp = { string.format("<%s%s>", root.xml, seri_args(root)) }
		for _,v in ipairs(root) do
			if type(v) == "table" then
				table.insert(tmp, seri(v))
			else
				table.insert(tmp, tostring(v))
			end
		end
		table.insert(tmp, string.format("</%s>", root.xml))
		return table.concat(tmp)
	end
end

function xml.seri(tbl)
	if tbl.xml then
		return seri(tbl)
	else
		local tmp = {}
		for _,v in ipairs(tbl) do
			table.insert(tmp, seri(v))
		end
		return table.concat(tmp)
	end
end

local escape_tbl = setmetatable({
	['&amp;'] = '&',
	['&quot;'] = '"',
	['&lt;'] = '<',
	['&gt;'] = '>',
}, { __index = function(_,k) return k:match"&#(%d+);":char() end })

function xml.unescape(str)
	str = str:gsub("(&[^;]+;)", escape_tbl)
	return str
end

return xml
