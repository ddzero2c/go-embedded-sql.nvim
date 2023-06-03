local M = {}

local embedded_sql = vim.treesitter.query.parse(
    "go",
    [[
        (call_expression
          (selector_expression
            field: (field_identifier) @field (#eq? @field "QueryContext")
          )
          (argument_list
            (raw_string_literal)@sql_string
          )
        )
    ]]
)

local get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "go", {})
    local tree = parser:parse()[1]
    return tree:root()
end

local function formatter(str)
    -- str = str:gsub("`", "'")
    local handle = io.popen("echo '" .. str .. "' | sql-formatter -l postgresql")
    local result = handle:read("*a")
    handle:close()
    return result
end

function M.format_sql()
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= "go" then
        vim.notify("can only be used in go")
        return
    end

    local root = get_root(bufnr)
    for id, node in embedded_sql:iter_captures(root, bufnr, 0, -1) do
        local name = embedded_sql.captures[id]
        if name == "sql_string" then
            local range = { node:range() }
            local sql_string = vim.treesitter.get_node_text(node, bufnr):sub(2, -2)

            local formatted = formatter(sql_string)
            local lines = {}
            for s in string.gmatch(formatted, "[^\n]+") do
                table.insert(lines, s)
            end

            vim.api.nvim_buf_set_lines(bufnr, range[1] + 1, range[3], false, lines)
        end
    end
end

return M
