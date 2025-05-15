# telescope-git-diff

A Telescope extension to quickly view and jump through all modified and untracked files in a git repository.

## Installation

Install with your favorite package manager.

### Optimal Installation (Lazy Loading)

Using `lazy.nvim` or similar, you can load the extension only when needed.

```lua
{
  "YouSame2/telescope-git-diff",
  lazy = true,
  cmd = "Telescope git_diff",
  keys = {
    {
      "<leader>fgd",
      function()
        require("telescope").extensions.git_diff.git_diff()
      end,
      desc = "Telescope Git Diff Hunks",
    },
  },
  config = function()
    require("telescope").load_extension("git_diff")
  end,
},
```

## Usage

Then you can use the command:

```vim
:Telescope git_diff
```

Or use the keymap you configured (e.g., `<leader>fgd` in the lazy loading example).
