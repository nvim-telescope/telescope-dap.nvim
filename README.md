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

## Launch.json support

`Telescope dap configurations` supports `launch.json` (as in VSCode). Any
configurations loaded from a `launch.json` file will be appended to the list
obtained from `dap.configurations`. See [VSCode
docs](https://code.visualstudio.com/docs/editor/debugging#_launch-configurations)
for `launch.json` format.

```viml
:Telescope dap configuration load_from_file=true " load configs from .vscode/launch.json
:Telescope dap configuration load_from_file=path/to/launch.json " load configs from path/to/launch.json
```
