local api = vim.api
local ts_utils = require 'nvim-treesitter.ts_utils'

local M = {}

local function is_sql_string(node)
    local src = ts_utils.get_node_text(node)[1]
    return src:find('SELECT') or src:find('INSERT') or
        src:find('UPDATE') or src:find('DELETE')
end

local function traverse_tree(node, action)
    if node:type() == 'raw_string_lit' then
        action(node)
    end
    for child in node:iter_children() do
        traverse_tree(child, action)
    end
end

function M.format_sql()
    local bufnr = api.nvim_get_current_buf()
    local ft = api.nvim_buf_get_option(bufnr, 'filetype')
    local parser = vim.treesitter.get_parser(bufnr, ft)

    -- Read configuration options from sqlformat.json.
    local options = {}
    local f = io.open('sqlformat.json', 'r')
    if f then
        options = vim.fn.json_decode(f:read('*all'))
        f:close()
    end

    -- Convert options to a string that can be passed to Node.js.
    local options_str = vim.fn.json_encode(options):gsub('"', '\\"')

    parser:for_each_tree(function(tstree)
        traverse_tree(tstree:root(), function(node)
            if is_sql_string(node) then
                local sql_string = ts_utils.get_node_text(node)[1]
                sql_string = sql_string:sub(2, -2)
                -- Pass options to sql-formatter.
                local formatted_sql = vim.fn.system(string.format(
                    'node -e "const sqlFormatter = require(\'sql-formatter\'); console.log(sqlFormatter.format(\'%s\', %s))"',
                    sql_string, options_str))
                ts_utils.update_selection(bufnr, node, '`' .. formatted_sql .. '`')
            end
        end)
    end)
end

return M
