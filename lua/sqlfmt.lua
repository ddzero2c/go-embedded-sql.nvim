local M = {}

local embedded_sql = vim.treesitter.query.parse(
    "go",
    [[
                (call_expression
                  (selector_expression
                    operand: (identifier) @operand
                    field: (field_identifier) @field (#contains? @field "QueryRow" "Exec" "Query" ))
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
    str = str:gsub("'", "\\'")
    local cmd = "node -e \"const sqlFormatter = require('sql-formatter'); console.log(sqlFormatter.format('" ..
        str .. "'))\""
    local output = {}
    local job = vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data then
                output = data
            end
        end,
        on_stderr = function(_, data)
            local err = table.concat(data)
            if data and err ~= "" then
                vim.notify("Improper sql syntax:", err)
            end
        end,
    })
    vim.fn.jobwait({ job })
    return output
end

function M.format_sql()
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= "go" then
        vim.notify("can only be used in go")
        return
    end

    local root = get_root(bufnr)

    local changes = {}
    for id, node in embedded_sql:iter_captures(root, bufnr, 0, -1) do
        local name = embedded_sql.captures[id]
        if name == "sql" then
            local range = { node:range() }
            local indentation = "    "

            local formatted = formatter(vim.treesitter.get_node_text(node, bufnr))

            for idx, line in ipairs(formatted) do
                formatted[idx] = indentation .. line
            end

            table.insert(changes, 1, { start = range[1] + 1, final = range[3], formatted = formatted })
        end
    end

    for _, change in ipairs(changes) do
        vim.api.nvim_buf_set_lines(bufnr, change.start, change.final, false, change.formatted)
    end
end
