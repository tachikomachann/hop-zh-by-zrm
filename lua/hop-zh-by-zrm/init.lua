local hop = require'hop'
local jump_regex = require'hop.jump_regex'
local zrm_table = require'hop-zh-by-zrm.zrm_table'
local hint = require'hop.hint'
local seg = require'hop-zh-by-zrm.seg'

local M = {}

local zh_word_regex = {
    oneshot = false,
    match = function(s)
        return seg.match(s)
    end,
}

local function map(mode, l, f, opts)
    vim.keymap.set(mode, l,
        function()
            M[f](opts)
        end,
        { remap = false }
    )
end

local function create_default_mappings()
    local directions = require('hop.hint').HintDirection
    map({'x', 'n', 'o'}, 'f', "hint_char1", {
        direction = directions.AFTER_CURSOR,
        current_line_only = true,
    })

    map({'x', 'n', 'o'}, 'F', "hint_char1", {
        direction = directions.BEFORE_CURSOR,
        current_line_only = true,
    })

    map({'x', 'n', 'o'}, 't', "hint_char1", {
        direction = directions.AFTER_CURSOR,
        current_line_only = true,
        hint_offset = -1,
    })

    map({'x', 'n', 'o'}, 'T', "hint_char1", {
        direction = directions.BEFORE_CURSOR,
        current_line_only = true,
        hint_offset = 1,
    })

    map('n', 's', "hint_char2", {multi_windows = true})
end

local function create_commands()
    local command = vim.api.nvim_create_user_command
    command("HopZrm1", function()
        M.hint_char1()
    end, {})
    command("HopZrm1BC", function()
        M.hint_char1({ direction = hint.HintDirection.BEFORE_CURSOR })
    end, {})
    command("HopZrm1AC", function()
        M.hint_char1({ direction = hint.HintDirection.AFTER_CURSOR })
    end, {})
    command("HopZrm1CurrentLine", function()
        M.hint_char1({ current_line_only = true })
    end, {})
    command("HopZrm1CurrentLineBC", function()
        M.hint_char1({ direction = hint.HintDirection.BEFORE_CURSOR, current_line_only = true })
    end, {})
    command("HopZrm1CurrentLineAC", function()
        M.hint_char1({ direction = hint.HintDirection.AFTER_CURSOR, current_line_only = true })
    end, {})
    command("HopZrm1MW", function()
        M.hint_char1({ multi_windows = true })
    end, {})

    -- The jump-to-char-2 command.
    command("HopZrm2", function()
        M.hint_char2()
    end, {})
    command("HopZrm2BC", function()
        M.hint_char2({ direction = hint.HintDirection.BEFORE_CURSOR })
    end, {})
    command("HopZrm2AC", function()
        M.hint_char2({ direction = hint.HintDirection.AFTER_CURSOR })
    end, {})
    command("HopZrm2CurrentLine", function()
        M.hint_char2({ current_line_only = true })
    end, {})
    command("HopZrm2CurrentLineBC", function()
        M.hint_char2({ direction = hint.HintDirection.BEFORE_CURSOR, current_line_only = true })
    end, {})
    command("HopZrm2CurrentLineAC", function()
        M.hint_char2({ direction = hint.HintDirection.AFTER_CURSOR, current_line_only = true })
    end, {})
    command("HopZrm2MW", function()
        M.hint_char2({ multi_windows = true })
    end, {})

    command("HopZhWords", function()
        M.hint_words_zh()
    end, {})
    command("HopZhWordsBC", function()
        M.hint_words_zh({ direction = hint.HintDirection.BEFORE_CURSOR })
    end, {})
    command("HopZhWordsAC", function()
        M.hint_words_zh({ direction = hint.HintDirection.AFTER_CURSOR })
    end, {})
    command("HopZhWordsCurrentLine", function()
        M.hint_words_zh({ current_line_only = true })
    end, {})
    command("HopZhWordsCurrentLineBC", function()
        M.hint_words_zh({ direction = hint.HintDirection.BEFORE_CURSOR, current_line_only = true })
    end, {})
    command("HopZhWordsCurrentLineAC", function()
        M.hint_words_zh({ direction = hint.HintDirection.AFTER_CURSOR, current_line_only = true })
    end, {})
    command("HopZhWordsMW", function()
        M.hint_words_zh({ multi_windows = true })
    end, {})
end

function M.hint_char1(opts)
    opts = setmetatable(opts or {}, {__index = M.opts})

    local ok, char_code = pcall(vim.fn.getchar)
    if not ok then
        return
    end

    local c = vim.fn.nr2char(char_code)
    local pat = zrm_table.char1pattern[c]
    local plain_text = false
    if not pat then
        plain_text = true
        pat = c
    end

    hop.hint_with_regex(
        jump_regex.regex_by_case_searching(pat, plain_text, opts),
        opts
    )
end

function M.hint_char2(opts)
    opts = setmetatable(opts or {}, {__index = M.opts})

    local ok, code1 = pcall(vim.fn.getchar)
    if not ok then
        return
    end

    local ok2, code2 = pcall(vim.fn.getchar)
    if not ok2 then
        return
    end

    local char1 = vim.fn.nr2char(code1)
    local char2 = vim.fn.nr2char(code2)
    local plain_text = false
    local pattern

    -- if we have a fallback key defined in the opts, if the second character is that key, we then fallback to the same
    -- behavior as hint_char1()
    if opts.char2_fallback_key == nil or
        char2 ~= vim.api.nvim_replace_termcodes(opts.char2_fallback_key, true, false, true) then
        pattern = zrm_table.char2pattern[char1..char2]
        if not pattern then
            plain_text = true
            pattern = char1..char2
        end
    else
        pattern = zrm_table.char1pattern[char1]
        if not pattern then
            plain_text = true
            pattern = char1
        end
    end

    hop.hint_with_regex(
        jump_regex.regex_by_case_searching(pattern, plain_text, opts),
        opts
    )
end

function M.hint_words_zh(opts)
    opts = setmetatable(opts or {}, {__index = M.opts})

    hop.hint_with_regex(zh_word_regex, opts)
end

-- Will be called by hop.nvim
function M.register(opts)
    M.opts = opts
    create_commands()
end

-- Called by lazy.nvim
function M.setup(opts)
    if opts.set_default_mappings then
        create_default_mappings()
    end
end

return M
