
# SQL Formatter for NeoVim

This is a NeoVim plugin that uses Tree-sitter and the `sql-formatter` NPM package to format embedded SQL strings in your code. It works across multiple languages that are supported by Tree-sitter.

## Requirements

* NeoVim 0.5.0 or later
* Node.js and NPM
* `sql-formatter` NPM package
* `nvim-treesitter` NeoVim plugin
* Tree-sitter grammar for each language you want to support

## Installation

You can install this plugin with a plugin manager like `vim-plug`. Add the following line to your `.vimrc` or `init.vim`:

```vim
Plug 'ddzero2c/sqlfmt.nvim', { 'do': './install_sql_formatter.sh' }
nnoremap <silent> <leader>sf :lua require('sqlfmt').format_sql()<CR>
```

After adding the line, run :PlugInstall in NeoVim to install the plugin.

## Usage
After installation, you can format SQL strings in your code with the key mapping <leader>sf. The plugin will format any string containing 'SELECT', 'INSERT', 'UPDATE', or 'DELETE' as a SQL string.

## Configuration
You can customize the output of sql-formatter by creating a sqlformat.json file in your project's root directory. For example:

```json
{
    "language": "sql",
    "indent": "    "
}
```
