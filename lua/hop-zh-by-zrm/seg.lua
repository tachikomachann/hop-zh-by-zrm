-- 中文分词（前向最大匹配）。纯 Lua，不依赖 nvim。
local words = require("hop-zh-by-zrm.words")
local M = {}

-- 返回 s 在 1-based 字节位置 i 处的 CJK 字符字节宽度；非 CJK 返回 0。
local function cjk_char_width(s, i)
	local b1 = s:byte(i)
	if not b1 then return 0 end
	-- 3 字节：U+4E00..U+9FFF 基本区（E4..E9 开头）
	if b1 >= 0xE4 and b1 <= 0xE9 then
		return 3
	end
	-- 4 字节：U+20000..U+323AF 扩展区（F0 开头，按 4 字节处理）
	if b1 == 0xF0 then
		return 4
	end
	return 0
end

-- 非 CJK 字符的 UTF-8 字节宽度（用于跳过）
local function char_width(s, i)
	local b1 = s:byte(i)
	if not b1 then return 0 end
	if b1 < 0x80 then return 1
	elseif b1 < 0xE0 then return 2
	elseif b1 < 0xF0 then return 3
	else return 4 end
end

local function make_match(set, max_len)
	return function(s)
		local i = 1
		local n = #s
		while i <= n do
			local cw = cjk_char_width(s, i)
			if cw > 0 then
				-- 前向最大匹配：从 i 开始取最长命中的词
				local matched_len
				local prefix = ""
				local j = i
				for _ = 1, max_len do
					local w = cjk_char_width(s, j)
					if w <= 0 then break end
					prefix = prefix .. s:sub(j, j + w - 1)
					if set[prefix] then
						matched_len = #prefix
					end
					j = j + w
				end
				if not matched_len then
					matched_len = cw -- 单字回退
				end
				return i - 1, i - 1 + matched_len
			else
				i = i + char_width(s, i)
			end
		end
		return nil
	end
end

M.make_match = make_match
M.match = make_match(words.set, words.max_len)

-- 从 byte 偏移 col（0-based，指向某字符起点）前进 offset 个字符，
-- 返回新的 byte 偏移（0-based，clamp 到行内：0 ~ 行尾）。
function M.char_offset(line, col, offset)
	local starts = {}
	local i = 1
	while i <= #line do
		starts[#starts + 1] = i - 1
		i = i + char_width(line, i)
	end
	starts[#starts + 1] = #line -- 行尾哨兵

	local char_idx = #starts - 1
	for k, s in ipairs(starts) do
		if s == col then
			char_idx = k - 1
			break
		end
	end

	char_idx = char_idx + offset
	if char_idx < 0 then char_idx = 0 end
	if char_idx > #starts - 1 then char_idx = #starts - 1 end

	return starts[char_idx + 1]
end

return M
