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

local function formatter(str)
    -- check for local config
    local config_file_path = vim.fn.getcwd() .. "/.sql-formatter.json"

    -- If the file exists, add the --config flag to the command
    local config = ""
    if vim.fn.filereadable(config_file_path) == 1 then
        config = "--config " .. config_file_path
    end

    local handle = io.popen("echo '" .. str .. "' | sql-formatter " .. config)
    local result = handle:read("*a")
    local success, _, code = handle:close()
    if not success then
        vim.notify("Failed to format SQL. Exit code: " .. tostring(code), vim.log.levels.ERROR)
        return str
    end

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
        if name == "sql" then
            local range = { node:range() }
            local sql_string = vim.treesitter.get_node_text(node, bufnr):sub(2, -2)

            local formatted = formatter(sql_string)
            if sql_string == formatted then
                -- Skip this node if the SQL didn't change
                goto continue
            end

            local lines = {}
            for s in string.gmatch(formatted, "[^\n]+") do
                table.insert(lines, s)
            end

            vim.api.nvim_buf_set_lines(bufnr, range[1] + 1, range[3], false, lines)
        end
        ::continue::
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

    -- Convert to 0-indexed
    start_row = start_row - 1
    end_row = end_row - 1

    local sql_string
    local formatted

    -- Single line selection
    if start_row == end_row then
        sql_string = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col + 1, {})[1]
        formatted = formatter(sql_string)
        if sql_string ~= formatted then
            -- Replace the original string with the formatted string
            local full_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
            local pre_string = full_line:sub(1, start_col)
            local post_string = full_line:sub(end_col + 2) -- +2 to keep the last backtick (`)
            -- Combine new lines
            local new_lines = { pre_string }
            for s in string.gmatch(formatted, "[^\n]+") do
                table.insert(new_lines, s)
            end
            table.insert(new_lines, post_string)
            -- Replace the original lines with new lines
            vim.api.nvim_buf_set_lines(bufnr, start_row, start_row + 1, false, new_lines)
        end
    else -- Multi-line selection
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        lines[1] = lines[1]:sub(start_col + 1)
        lines[#lines] = lines[#lines]:sub(1, end_col)
        sql_string = table.concat(lines, "\n")

        formatted = formatter(sql_string):sub(0, -2)
        if sql_string ~= formatted then
            vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, vim.split(formatted, "\n"))
        end
    end
end

return M

