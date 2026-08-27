-- 在仓库根目录运行：lua tests/test_words.lua
package.path = "./lua/?.lua;" .. package.path

local seg = require("hop-zh-by-zrm.seg")

local function collect_words(s, m)
	m = m or seg.match
	local out = {}
	local idx = 1
	while true do
		local b, e = m(s:sub(idx))
		if b == nil then break end
		out[#out + 1] = s:sub(idx + b, idx + e - 1)
		idx = idx + e
	end
	return out
end

-- 1) 注入词表：FMM 切分
local m = seg.make_match({ ["你好"] = true, ["世界"] = true }, 2)
local t = collect_words("你好世界", m)
assert(#t == 2 and t[1] == "你好" and t[2] == "世界", "你好世界 应切成 你好/世界，实际: " .. table.concat(t, "/"))

-- 2) 跳过英文
local t2 = collect_words("abc你好def世界", m)
assert(#t2 == 2 and t2[1] == "你好" and t2[2] == "世界", "应跳过英文，实际: " .. table.concat(t2, "/"))

-- 3) OOV 单字回退
local t3 = collect_words("的", m)
assert(#t3 == 1 and t3[1] == "的", "单字应回退，实际: " .. table.concat(t3, "/"))

-- 4) 无中文返回空
local t4 = collect_words("hello", m)
assert(#t4 == 0, "无中文应返回空")

-- 5) 真实词表抽查
local real = collect_words("你好世界")
assert(#real >= 2, "真实词表应能切分 你好世界")
assert(real[1] == "你好", "真实词表首词应为 你好，实际: " .. tostring(real[1]))

-- 6) char_offset：按字符（非 cell）偏移，供 t/T 使用
local function assert_eq(a, b, msg)
	if a ~= b then error((msg or "assert_eq failed") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end
assert_eq(seg.char_offset("你好世界", 6, -1), 3, "世 前一个字应为 好(byte 3)")
assert_eq(seg.char_offset("你好世界", 6, 1), 9, "世 后一个字应为 界(byte 9)")
assert_eq(seg.char_offset("你好世界", 0, -1), 0, "行首 clamp 到 0")
assert_eq(seg.char_offset("你好世界", 9, 1), 12, "行尾 clamp 到行尾")
assert_eq(seg.char_offset("abc", 1, -1), 0, "英文 b 前为 a")
assert_eq(seg.char_offset("abc", 1, 1), 2, "英文 b 后为 c")

print("test_words: OK")
