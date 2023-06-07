local M = {}

local embedded_sql = vim.treesitter.query.parse(
    "go",
    [[
        (call_expression
          (selector_expression
            field: (field_identifier) @field
            (#match? @field "^(Query|QueryContext|Exec|ExecContext|Prepare|PrepareContext)$")
          )
          (argument_list
            (raw_string_literal) @sql
          )
        )
    ]]
)

local get_root = function(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "go", {})
    local tree = parser:parse()[1]
    return tree:root()
end

local run_formatter = function(lines)
    -- local result = table.concat(vim.list_slice(split, 2, #split - 1), "\n")
    local result = table.concat(lines, "\n")
    local config_file_path = vim.fn.getcwd() .. "/.sql-formatter.json"
    local j = require("plenary.job"):new {
        command = "sql-formatter",
        args = { "--config", config_file_path },
        writer = { result },
    }
    return j:sync()
end

function M.format_sql(bufnr)
    local bufnr = bufnr or vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= "go" then
        vim.notify("can only be used in go")
        return
    end

    local changes = {}
    local root = get_root(bufnr)
    for id, node in embedded_sql:iter_captures(root, bufnr, 0, -1) do
        local name = embedded_sql.captures[id]
        if name == "sql" then
            local range = { node:range() }
            local text = vim.treesitter.get_node_text(node, bufnr):gsub('`', '')
            local lines = vim.split(text, "\n")

            local formatted = run_formatter(lines)
            table.insert(formatted, 1, "")
            table.insert(changes, 1, {
                start_row = range[1],
                start_col = range[2] + 1,
                end_row = range[3],
                end_col = range[4] - 1,
                start = range[1] + 1,
                final = range[3],
                formatted = formatted
            })
        end
    end

    for _, change in ipairs(changes) do
        -- vim.api.nvim_buf_set_lines(bufnr, change.start, change.final, false, change.formatted)
        vim.api.nvim_buf_set_text(bufnr, change.start_row, change.start_col, change.end_row, change.end_col,
            change.formatted)
    end
end

function M.format_sql_visual()
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= "go" then
        vim.notify("can only be used in go")
        return
    end

    local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '<'))
    local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '>'))
    print(start_row, start_col, end_row, end_col)
    -- 2147483647

    -- Convert to 0-indexed
    start_row = start_row - 1
    end_row = end_row - 1

    local sql_string
    local formatted

    -- Single line selection
    if start_row == end_row then
        if end_col == 2147483647 then
            sql_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
        else
            sql_lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col + 1, {})
        end
        formatted = run_formatter(sql_lines)
        if #formatted > 1 then
            table.insert(formatted, 1, "")
        end
        vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, start_col + #sql_lines[1],
            formatted)
    else -- Multi-line selection
        if end_col == 2147483647 then
            sql_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        else
            sql_lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col + 1, {})
        end
        formatted = run_formatter(sql_lines)
        vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, #sql_lines[#sql_lines],
            formatted)
    end
end

return M
