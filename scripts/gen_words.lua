-- 从 jieba 词典生成 lua/hop-zh-by-zrm/words.lua（中文词表）。
-- 用法（在仓库根目录运行）：lua scripts/gen_words.lua
local M = {}

local JIEBA_DICT = "/usr/share/opencc/jieba_dict/jieba.dict.utf8"
local MIN_LEN = 2
local MAX_LEN = 6
local FREQ_MIN = 10

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

-- 是否 CJK 汉字（与 gen_zrm.lua 相同区间）
function M.is_cjk(char)
	local cp = utf8_codepoint(char)
	if cp == 0x3007 then return true end -- 〇
	if cp >= 0x3400 and cp <= 0x4DBF then return true end
	if cp >= 0x4E00 and cp <= 0x9FFF then return true end
	if cp >= 0xF900 and cp <= 0xFAFF then return true end
	if cp >= 0x20000 and cp <= 0x2A6DF then return true end
	if cp >= 0x2A700 and cp <= 0x2EBEF then return true end
	if cp >= 0x30000 and cp <= 0x323AF then return true end
	return false
end

local function char_byte_width(b1)
	if b1 < 0x80 then return 1
	elseif b1 < 0xE0 then return 2
	elseif b1 < 0xF0 then return 3
	else return 4 end
end

-- 是否纯中文词（每个字符都是 CJK）
function M.is_cjk_word(word)
	local i = 1
	while i <= #word do
		local n = char_byte_width(word:byte(i))
		if not M.is_cjk(word:sub(i, i + n - 1)) then return false end
		i = i + n
	end
	return true
end

-- 解析词典内容，返回过滤后的词集
function M.parse(content)
	local set = {}
	for line in content:gmatch("[^\r\n]+") do
		local word, freq = line:match("^(%S+)%s+(%d+)")
		if word and freq then
			local f = tonumber(freq)
			if f and f >= FREQ_MIN and M.is_cjk_word(word) then
				local i, len = 1, 0
				while i <= #word do
					i = i + char_byte_width(word:byte(i))
					len = len + 1
				end
				if len >= MIN_LEN and len <= MAX_LEN then
					set[word] = true
				end
			end
		end
	end
	return set
end

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end
	table.sort(keys)
	return keys
end

function M.render(set, max_len)
	local out = { "return {" }
	out[#out + 1] = "    max_len = " .. max_len .. ","
	out[#out + 1] = "    set = {"
	for _, w in ipairs(sorted_keys(set)) do
		out[#out + 1] = '        ["' .. w .. '"] = true,'
	end
	out[#out + 1] = "    },"
	out[#out + 1] = "}"
	return table.concat(out, "\n") .. "\n"
end

function M.main()
	local f = assert(io.open(JIEBA_DICT, "r"))
	local content = f:read("*a")
	f:close()

	local set = M.parse(content)
	local rendered = M.render(set, MAX_LEN)

	local out = assert(io.open("lua/hop-zh-by-zrm/words.lua", "w"))
	out:write(rendered)
	out:close()
	print(("generated lua/hop-zh-by-zrm/words.lua (%d words, max_len=%d)")
		:format(#sorted_keys(set), MAX_LEN))
end

-- 直接运行时执行 main；被 dofile 引入时不执行
local function basename(p)
	return p:match("([^/\\]+)$") or p
end
if arg and arg[0] and basename(arg[0]) == "gen_words.lua" then
	M.main()
end

return M
