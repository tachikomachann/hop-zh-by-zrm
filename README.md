# hop-zh-by-zrm

让 [hop.nvim](https://github.com/smoka7/hop.nvim) 支持中文跳转的扩展，基于**自然码双拼**编码与**中文词典分词**。

## 功能

1. **单字跳转（自然码双拼）**：按 1~2 个键，跳到对应自然码编码的汉字 —— `hint_char1` / `hint_char2`，命令 `HopZrm1*` / `HopZrm2*`。
2. **词首跳转（中文分词）**：按词典把中文切成词，跳转到每个词首 —— `hint_words_zh`，命令 `HopZhWords*`。

## 介绍

- 只能在 Neovim 中运行, 包括 [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim).
- 本插件是[hop.nvim](https://github.com/smoka7/hop.nvim)的一个扩展(extension), 它能让[hop.nvim](https://github.com/smoka7/hop.nvim)识别中文, 它必须依赖[hop.nvim](https://github.com/smoka7/hop.nvim)才能运行.

## 安装

- 本插件不可独立运行, 它依赖于[hop.nvim](https://github.com/smoka7/hop.nvim).
- 使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 进行安装:

```lua
return {
    'zzhirong/hop-zh-by-zrm',
    dependencies = {
        'smoka7/hop.nvim',
    },
    config = function()
        local hop_zrm = require"hop-zh-by-zrm"
        hop_zrm.setup({
            -- 注意: 本扩展的默认映射覆盖掉了一些常用的映射: f, F, t, T, s
            -- 设置 set_default_mappings 为 false 可关闭默认映射.
            set_default_mappings = true,
        })
    end
}
```

## 配置

- 将此扩展加入[hop.nvim](https://github.com/smoka7/hop.nvim) extension 配置项.
- 使用 lazy 配置样例:

```lua
return{
    'smoka7/hop.nvim',
    config = function()
        local hop = require('hop')
        hop.setup {
            keys = 'etovxqpdygfblzhckisuran',
            extensions = {
                'hop-zh-by-zrm',
            },
        }
    end,
}
```

## 使用

### 单字跳转（自然码双拼）

- 通过命令: 本扩展创建了 `HopZrm1*`, `HopZrm2*`, 比如 `:HopZrm1`.
- 通过调用 api: `hop_zrm.hint_char1({opts})` 和 `hop_zrm.hint_char2({opts})`, 比如 `:lua require('hop-zh-by-zrm').hint_char1()`, 帮助文档请查看`hop.hint_char1`和`hop.hint_char2`.
- 通过默认/自定义映射:
    - 默认设置`set_default_mappings`为`true`:
        - `f`, `F`, `T`, `t`: 功能与覆盖前相同, 只不过多了跳转目标.
        - `s`映射成`require('hop-zh-by-zrm').hint_char2()`.

### 词首跳转（中文分词）

- 通过命令: 本扩展创建了 `HopZhWords*`, 比如 `:HopZhWords`.
- 通过调用 api: `hop_zrm.hint_words_zh({opts})`, 支持 `direction` / `current_line_only` / `multi_windows` 等 hop 选项.
- 示例映射（向前 / 向后）:

```lua
vim.keymap.set({ "n", "x", "o" }, "<leader>z", function()
    require("hop-zh-by-zrm").hint_words_zh({
        direction = require("hop.hint").HintDirection.AFTER_CURSOR,  -- 向前
    })
end, { desc = "Hop Chinese word forward" })

vim.keymap.set({ "n", "x", "o" }, "<leader>x", function()
    require("hop-zh-by-zrm").hint_words_zh({
        direction = require("hop.hint").HintDirection.BEFORE_CURSOR, -- 向后
    })
end, { desc = "Hop Chinese word backward" })
```

## 帮助

- 查看[hop.nvim](https://github.com/smoka7/hop.nvim)对应命令帮助文档, 比如, 想要查看`HopZrm1`帮助,

## 字典与重新生成

### 自然码单字数据

自然码双拼数据由 `zrm_dict.yaml`（自然码2000 单字编码字典）生成，脚本为 `scripts/gen_zrm.lua`。

```bash
# 在仓库根目录运行
lua scripts/gen_zrm.lua
```

运行后重新生成 `lua/hop-zh-by-zrm/zrm_table.lua`。

### 中文分词词库

中文分词词库由 `scripts/gen_words.lua` 从 jieba 词典（`/usr/share/opencc/jieba_dict/jieba.dict.utf8`，需系统安装 opencc）裁剪生成：纯中文词、长度 2–6 字、词频 ≥ 10，输出 `lua/hop-zh-by-zrm/words.lua`。

```bash
# 在仓库根目录运行
lua scripts/gen_words.lua
```

运行后重新生成 `lua/hop-zh-by-zrm/words.lua`。
