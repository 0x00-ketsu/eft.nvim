# Eft.nvim

A Neovim plugin written in Lua.

Highlight character(s) in line when press keyboard `f` `t` `F` `T`.

![screenshot](https://user-images.githubusercontent.com/16932133/215315715-c3b22e6f-700b-4465-83be-aca68abba059.png)

## Installation

[Packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use {
  '0x00-ketsu/eft.nvim',
  config = function()
    require('eft').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  end
}
```

## Setup

Following defaults:

```lua
local eft = require('eft')
eft.setup(
    {
      ignore_case = false,          -- true: case insensitive
      -- Do not change subitem order of highlights
      highlights = {
        {
          name = 'EftChar',         -- name of highlight
          allow_space = true,       -- true: highlight for space
          color = {                 -- color for highlight
            gui = 'bold,underline',
            guifg = 'Orange',
            cterm = 'bold,underline',
            ctermfg = 'Red'
          }
        },
        {
          name = 'EftSubChar',
          allow_space = false,
          color = {
            gui = 'bold,underline',
            guifg = 'Gray',
            cterm = 'bold,underline',
            ctermfg = 'Gray'
          }
        }
      }
    }
)
```

## Keymaps

```lua
vim.api.nvim_set_keymap('n', 'f', '<CMD>lua require("action").eft_f()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'F', '<CMD>lua require("action").eft_F()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 't', '<CMD>lua require("action").eft_t()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'T', '<CMD>lua require("action").eft_T()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', ';', '<CMD>lua require("action").eft_repeat()<CR>', {noremap = true, silent = true})
```

## Thanks

- [vim-eft](https://github.com/hrsh7th/vim-eft)

## License

MIT
