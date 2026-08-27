-- 在仓库根目录运行：lua tests/test_load.lua
package.path = "./lua/?.lua;" .. package.path

local function assert_contains(str, sub, msg)
	if type(str) ~= "string" or not str:find(sub, 1, true) then
		error((msg or "assert_contains failed") .. ": " .. tostring(sub), 2)
	end
end

local zrm_table = require("hop-zh-by-zrm.zrm_table")

-- 抽查自然码映射
assert_contains(zrm_table.char2pattern["bj"], "班", "bj 应含 班")
assert_contains(zrm_table.char2pattern["hl"], "海", "hl 应含 海")
assert_contains(zrm_table.char2pattern["by"], "冰", "by 应含 冰")
assert_contains(zrm_table.char2pattern["vs"], "中", "vs 应含 中")
assert_contains(zrm_table.char2pattern["dp"], "顿", "dp 应含 顿")
assert_contains(zrm_table.char1pattern["b"], "班", "char1[b] 应含 班")
assert_contains(zrm_table.char1pattern["b"], "冰", "char1[b] 应含 冰")

-- 标点保留
assert_contains(zrm_table.char1pattern["."], "。", "char1[.] 应含 。")
assert(zrm_table.char1pattern["["] ~= nil, "char1[[ 应有值")

-- 不应包含非汉字符号
for _, c in ipairs({ "β", "¤", "ㄅ" }) do
	for _, class in pairs(zrm_table.char2pattern) do
		assert(not class:find(c, 1, true), "非汉字符 " .. c .. " 不应出现")
	end
	for _, class in pairs(zrm_table.char1pattern) do
		assert(not class:find(c, 1, true), "非汉字符 " .. c .. " 不应出现")
	end
end

-- init.lua 语法检查（只编译不执行，避免依赖未安装的 hop.nvim）
local chunk, err = loadfile("lua/hop-zh-by-zrm/init.lua")
assert(chunk ~= nil, "init.lua 语法错误: " .. tostring(err))

-- 回归：不得引用 hop.nvim v1 专有 API（v2 已移除，会导致运行时 nil 调用）
local src_f = assert(io.open("lua/hop-zh-by-zrm/init.lua", "r"))
local src = src_f:read("*a")
src_f:close()
for _, v1api in ipairs({
	"jump_targets_by_scanning_lines",
	"jump_targets_for_current_line",
	"jump_target.regex_by_case_searching",
}) do
	assert(not src:find(v1api, 1, true), "不应引用 hop v1 API: " .. v1api)
end

-- 回归：init.lua 应提供中文词首跳转接口与命令
assert(src:find("hint_words_zh", 1, true) ~= nil, "init.lua 应提供 hint_words_zh")
assert(src:find("HopZhWords", 1, true) ~= nil, "init.lua 应创建 HopZhWords 命令")

-- 回归：t/T 与 operator-pending 偏移应按字符处理（修复多字节中文错位）
assert(src:find("seg.char_offset", 1, true) ~= nil, "init.lua 应使用 seg.char_offset 做字符偏移")
assert(src:find("nvim_get_mode", 1, true) ~= nil, "init.lua 应处理 operator-pending 模式")

print("test_load: OK")
