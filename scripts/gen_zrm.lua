-- 从 zrm_dict.yaml 生成 lua/hop-zh-by-zrm/zrm_table.lua（自然码双拼数据）。
-- 用法（在仓库根目录运行）：lua scripts/gen_zrm.lua
local M = {}

-- 单个 UTF-8 字符 → Unicode 码点
local function utf8_codepoint(s)
	local b1 = s:byte(1)
	if b1 < 0x80 then
		return b1
	elseif b1 < 0xE0 then
		return ((b1 % 0x20) * 0x40) + (s:byte(2) % 0x40)
	elseif b1 < 0xF0 then
		return ((b1 % 0x10) * 0x1000)
			+ ((s:byte(2) % 0x40) * 0x40)
			+ (s:byte(3) % 0x40)
	else
		return ((b1 % 0x08) * 0x40000)
			+ ((s:byte(2) % 0x40) * 0x1000)
			+ ((s:byte(3) % 0x40) * 0x40)
			+ (s:byte(4) % 0x40)
	end
end

-- 是否保留（仅汉字）
function M.is_cjk(char)
	local cp = utf8_codepoint(char)
	if cp == 0x3007 then return true end -- 〇
	if cp >= 0x3400 and cp <= 0x4DBF then return true end -- 扩展 A
	if cp >= 0x4E00 and cp <= 0x9FFF then return true end -- 基本区
	if cp >= 0xF900 and cp <= 0xFAFF then return true end -- 兼容表意文字
	if cp >= 0x20000 and cp <= 0x2A6DF then return true end -- 扩展 B
	if cp >= 0x2A700 and cp <= 0x2EBEF then return true end -- 扩展 C–F
	if cp >= 0x30000 and cp <= 0x323AF then return true end -- 扩展 G–H
	return false
end

-- 解析 yaml 内容，返回 code -> 去重后的字符列表（保持出现顺序）
function M.parse(content)
	local char2 = {}
	local seen = {}
	for line in content:gmatch("[^\r\n]+") do
		if line:find("\t", 1, true) then
			local char, code = line:match("^([^\t]+)\t([%a]+)$")
			if char and code and #code == 2 and M.is_cjk(char) then
				local list = char2[code]
				if not list then
					list = {}
					char2[code] = list
					seen[code] = {}
				end
				if not seen[code][char] then
					seen[code][char] = true
					list[#list + 1] = char
				end
			end
		end
	end
	return char2
end

-- 由 char2 构建 char1：字母 -> 以该字母开头的所有码的字符并集
function M.build_char1patterns(char2)
	local codes = {}
	for code in pairs(char2) do
		codes[#codes + 1] = code
	end
	table.sort(codes)

	local result = {}
	local seen = {}
	for _, code in ipairs(codes) do
		local letter = code:sub(1, 1)
		local list = result[letter]
		if not list then
			list = {}
			result[letter] = list
			seen[letter] = {}
		end
		for _, c in ipairs(char2[code]) do
			if not seen[letter][c] then
				seen[letter][c] = true
				list[#list + 1] = c
			end
		end
	end
	return result
end

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end
	table.sort(keys)
	return keys
end

-- 标点键：与双拼方案无关，沿用原 hop 小鹤方案的值（原样保留 6 项）
local CHAR1_PUNCT = [=[
        ['.'] = '[.。]',
        ['['] = '\\[',
        [','] = '[,，]',
        ['?'] = '[?？]',
        [':'] = '[:：]',
        [';'] = '[;；]',]=]

-- 构造 hop 正则长字符串源码：
-- char1: [[\%([a...]\)]]
local function char1_regex(letter, chars)
	return "[[" .. "\\%([" .. letter .. chars .. "]\\)" .. "]]"
end

-- char2: [[\%(bj\|[...]\)]]
local function char2_regex(code, chars)
	return "[[" .. "\\%(" .. code .. "\\|[" .. chars .. "]\\)" .. "]]"
end

-- 渲染为 zrm_table.lua 的源码
function M.render(char2, char1)
	local out = { "return {" }
	out[#out + 1] = "    char1pattern = {"
	out[#out + 1] = CHAR1_PUNCT
	for _, letter in ipairs(sorted_keys(char1)) do
		local chars = table.concat(char1[letter], "")
		out[#out + 1] = "        ['" .. letter .. "'] = " .. char1_regex(letter, chars) .. ","
	end
	out[#out + 1] = "    },"
	out[#out + 1] = "    char2pattern = {"
	for _, code in ipairs(sorted_keys(char2)) do
		local chars = table.concat(char2[code], "")
		out[#out + 1] = "        ['" .. code .. "'] = " .. char2_regex(code, chars) .. ","
	end
	out[#out + 1] = "    },"
	out[#out + 1] = "}"
	return table.concat(out, "\n") .. "\n"
end

function M.main()
	local f = assert(io.open("zrm_dict.yaml", "r"))
	local content = f:read("*a")
	f:close()

	local char2 = M.parse(content)
	local char1 = M.build_char1patterns(char2)
	local rendered = M.render(char2, char1)

	local out = assert(io.open("lua/hop-zh-by-zrm/zrm_table.lua", "w"))
	out:write(rendered)
	out:close()
	print(("generated lua/hop-zh-by-zrm/zrm_table.lua (%d codes, %d letters)")
		:format(#sorted_keys(char2), #sorted_keys(char1)))
end

-- 直接运行时执行 main；被 dofile 引入时不执行
local function basename(p)
	return p:match("([^/\\]+)$") or p
end
if arg and arg[0] and basename(arg[0]) == "gen_zrm.lua" then
	M.main()
end

return M
