# telescope-dap.nvim

Integration for [nvim-dap](https://github.com/mfussenegger/nvim-dap) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

This plugin is also overriding `dap` internal ui, so running any `dap` command, which makes use of the internal ui, will result in a `telescope` prompt.

## Requirements

- [nvim-dap](https://github.com/mfussenegger/nvim-dap) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (optional)

## Setup

You can setup the extension by doing

```lua
require('telescope').load_extension('dap')
```

somewhere after your require('telescope').setup() call.

If you want to disable overwriting the `dap` internal ui, for example because you already use a different plugin to overwrite `vim.ui.select`,
you can do so by configuring the extension as part of the telescope setup.

```lua
require('telescope').setup({
  extensions = {
    dap = {
      overwrite_pick_one = false
    }
  }
})
```

## Available commands

```viml
:Telescope dap commands
:Telescope dap configurations
:Telescope dap list_breakpoints
:Telescope dap variables
:Telescope dap frames
```

## Available functions

```lua
require'telescope'.extensions.dap.commands{}
require'telescope'.extensions.dap.configurations{}
require'telescope'.extensions.dap.list_breakpoints{}
require'telescope'.extensions.dap.variables{}
require'telescope'.extensions.dap.frames{}
```

## Customize Colors

Stack frames coming from external code (libraries) are highlighted with the "NvimDapSubtleFrame" highlight group (by default linked to "Comment").
