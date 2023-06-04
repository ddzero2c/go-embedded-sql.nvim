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
    local config_file_path = vim.fn.getcwd() .. "/.sqlformat"

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

return M
