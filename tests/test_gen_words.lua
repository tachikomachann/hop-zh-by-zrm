-- 在仓库根目录运行：lua tests/test_gen_words.lua
local M = dofile("scripts/gen_words.lua")

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "assert_eq failed")
			.. "\n  expected: " .. tostring(expected)
			.. "\n  actual:   " .. tostring(actual), 2)
	end
end

local function assert_contains(str, sub, msg)
	if type(str) ~= "string" or not str:find(sub, 1, true) then
		error((msg or "assert_contains failed") .. ": " .. tostring(sub), 2)
	end
end

-- 1) CJK 判断
assert_eq(M.is_cjk("中"), true, "中 应为 CJK")
assert_eq(M.is_cjk("β"), false, "β 不应为 CJK")
assert_eq(M.is_cjk_word("你好"), true, "你好 应为纯中文词")
assert_eq(M.is_cjk_word("你a"), false, "你a 不应为纯中文词")

-- 2) parse 过滤：词频、纯中文、长度 2–6
local sample = table.concat({
	"你好 100 l",
	"世界 50 n",
	"计算机 30 n",
	"低频词 3 n",          -- freq < 10 → 过滤
	"a你 100 l",           -- 非纯中文 → 过滤
	"一 100 m",            -- 单字 → 过滤
	"一二三四五六七 100 l", -- 7 字 → 过滤
}, "\n")

local set = M.parse(sample)
assert_eq(set["你好"], true, "你好 应保留")
assert_eq(set["世界"], true, "世界 应保留")
assert_eq(set["计算机"], true, "计算机 应保留")
assert_eq(set["低频词"], nil, "低频词应被过滤")
assert_eq(set["a你"], nil, "非纯中文应被过滤")
assert_eq(set["一"], nil, "单字应被过滤")
assert_eq(set["一二三四五六七"], nil, "超长应被过滤")

-- 3) render 输出格式
local rendered = M.render(set, 6)
assert_contains(rendered, "return {")
assert_contains(rendered, "max_len = 6,")
assert_contains(rendered, "set = {")
assert_contains(rendered, '["你好"] = true,')

print("test_gen_words: OK")
