# go-embedded-sql

This neovim plugin formats embedded SQL strings using the sql-formatter tool. It is specifically designed for use with the Go programming language.

## Installation
Install the sql-formatter tool globally on your system.

```bash
npm install -g sql-formatter
```

Install the plugin using your preferred package manager for neovim. For example, using vim-plug:

```vim
Plug 'ddzero2c/go-embedded-sql'
```

## Usage
```vim
:lua require('go-embedded-sql').format_sql()
```

or you could set keymap like this:
```lua
vim.api.nvim_buf_set_keymap(bufnr, 'v', '<leader>sf', ':lua require("go-embedded-sql").format_sql_visual()<CR>', opts)
vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>sf', ':lua require("go-embedded-sql").format_sql()<CR>', opts)
```

## Configuration
You can customize the output of sql-formatter by creating a .sql-formatter.json file in your project's root directory. For example:

```json
{
    "language": "sql",
    "indent": "    "
}
```
