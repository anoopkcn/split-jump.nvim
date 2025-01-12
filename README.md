# split-jump.nvim

A Neovim plugin that provides seamless navigation between Neovim splits and tmux panes using the same keybindings.

## Features

- Seamless navigation between Neovim splits and tmux panes
- Optional preservation of tmux zoom state
- Optional wrapping prevention when navigating

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "anoopkcn/split-jump.nvim" }
```

If you have TMUX, Add the following lines to tmux configuration for split navigation:

```bash
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?|fzf)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
bind-key -n 'C-\' if-shell "$is_vim" 'send-keys C-\\' 'select-pane -l'
```
credits for tmux keybinding: [christoomey](https://github.com/christoomey/vim-tmux-navigator)

## Default Keymaps

- `<C-h>` - Navigate left
- `<C-j>` - Navigate down
- `<C-k>` - Navigate up
- `<C-l>` - Navigate right
- `<C-\>` - Navigate to previous split/pane

You can set your own keybinding after setting the option `mappings = false`

## Commands

The plugin provides the following commands:

- `:SplitJumpLeft` - Navigate left
- `:SplitJumpDown` - Navigate down
- `:SplitJumpUp` - Navigate up
- `:SplitJumpRight` - Navigate right
- `:SplitJumpPrevious` - Navigate to previous split/pane

## Configuration

```lua
{
    "anoopkcn/split-jump.nvim",
    config = function()
        require("split-jump").setup({
            -- your configuration goes here
            -- The following are the default configurations ...
            -- ... change them to your liking

            -- Enable/disable default mappings
            mappings = true,

            -- Disable navigation when tmux pane is zoomed
            disable_when_zoomed = false,

            -- Save behavior when switching panes:
            -- 0: no save
            -- 1: save current buffer
            -- 2: save all buffers
            save_on_switch = 0,

            -- Preserve tmux zoom state when navigating
            preserve_zoom = false,

            -- Prevent wrapping when navigating
            no_wrap = false,

            -- Disable the netrw <C-l> mapping workaround
            disable_netrw_workaround = true
        })
    end,
}
```

## Note
`<C-l>` is a default netrw mapping. `split-jump` will override this mapping. set custom mappings to avoid this remap if you wish.

## Requirements

- Neovim >= 0.5.0
- tmux >= 3.0 (optional - for tmux integration)


## Inspiration
This plugin is a lua rewrite of the `vim-tmux-navigator` plugin by [christoomey](https://github.com/christoomey/vim-tmux-navigator)
