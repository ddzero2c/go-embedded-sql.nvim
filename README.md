# go-embedded-sql

This neovim plugin formats embedded SQL strings using the sql-formatter tool. It is specifically designed for use with the Go programming language.

## Installation
Install the sql-formatter tool globally on your system.

Install the plugin using your preferred package manager for neovim. For example, using vim-plug:

```vim
Plug 'ddzero2c/go-embedded-sql'
```

## Usage
```vim
:lua require('sqlfmt').format_sql()
```

## Configuration
You can customize the output of sql-formatter by creating a .sqlformat.json file in your project's root directory. For example:

```json
{
    "language": "sql",
    "indent": "    "
}
```
