-- 在仓库根目录运行：lua tests/test_gen_zrm.lua
local M = dofile("scripts/gen_zrm.lua")

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

local function assert_in_array(arr, value, msg)
	for _, v in ipairs(arr) do
		if v == value then return end
	end
	error((msg or "assert_in_array failed") .. ": " .. tostring(value), 2)
end

local function assert_not_in_array(arr, value, msg)
	for _, v in ipairs(arr) do
		if v == value then
			error((msg or "assert_not_in_array failed") .. ": " .. tostring(value), 2)
		end
	end
end

-- 1) is_cjk 过滤
assert_eq(M.is_cjk("中"), true, "中 应为 CJK")
assert_eq(M.is_cjk("〇"), true, "〇 应为 CJK")
assert_eq(M.is_cjk("β"), false, "β 不应为 CJK")
assert_eq(M.is_cjk("¤"), false, "¤ 不应为 CJK")
assert_eq(M.is_cjk("ㄅ"), false, "ㄅ 不应为 CJK")

-- 2) parse：仅保留汉字、去重、仅 2 字母码
local sample = table.concat({
	"---",
	"name: zrm2000",
	"",
	"班\tbj",
	"班\tbj",
	"海\thl",
	"冰\tby",
	"中\tvs",
	"啊\taa",
	"β\tbd",
	"¤\tva",
	"爱\tai",
}, "\n")

local char2 = M.parse(sample)
assert_eq(#char2["bj"], 1, "重复的 班 应去重")
assert_eq(char2["bj"][1], "班")
assert_eq(char2["hl"][1], "海")
assert_eq(char2["by"][1], "冰")
assert_eq(char2["vs"][1], "中")
assert_eq(char2["aa"][1], "啊")
assert_eq(char2["ai"][1], "爱")
assert_eq(char2["bd"], nil, "非汉字码 bd 应被丢弃")
assert_eq(char2["va"], nil, "非汉字码 va 应被丢弃")

-- 3) build_char1patterns 前缀并集
local char1 = M.build_char1patterns(char2)
assert_in_array(char1["b"], "班", "char1[b] 应含 班(bj)")
assert_in_array(char1["b"], "冰", "char1[b] 应含 冰(by)")
assert_not_in_array(char1["b"], "海", "char1[b] 不应含 海(hl)")
assert_in_array(char1["h"], "海", "char1[h] 应含 海(hl)")
assert_in_array(char1["a"], "啊", "char1[a] 应含 啊(aa)")
assert_in_array(char1["a"], "爱", "char1[a] 应含 爱(ai)")

-- 4) render 输出格式（hop 正则格式）
local rendered = M.render(char2, char1)
assert_contains(rendered, "return {")
assert_contains(rendered, "char1pattern = {")
assert_contains(rendered, "char2pattern = {")
assert_contains(rendered, "['.'] = '[.。]',")
assert_contains(rendered, [=[['bj'] = [[\%(bj\|[班]\)]],]=])
assert_contains(rendered, [=[['b'] = [[\%([b班冰]\)]],]=])

print("test_gen_zrm: OK")
