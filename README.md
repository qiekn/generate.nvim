# generate.nvim

Generate C++ class method implementations.

## Notes

我 fork 了这个仓库之后的修改是 Opus 4.6 生成的，作为一个工具用用，凑活凑活吧。

![Image](https://github.com/user-attachments/assets/2b1ccbda-36bc-40a4-8618-98b38d3c8947)

## Preview

https://github.com/user-attachments/assets/aa1088f8-3d4f-4b82-8772-5a48eae86f15

## :package: Installation

The plugin depends on [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
and the C++ parser, which can be installed via `:TSInstall cpp`

[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "qiekn/generate.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = { "Generate", "CppImpl" },
  keys = {
    { "<leader>ci", "<cmd>Generate implementations<cr>", desc = "Generate C++ implementations", ft = { "cpp", "c" } },
    { "<leader>ci", ":'<,'>Generate implementations<cr>", mode = "v", desc = "Generate selected implementations", ft = { "cpp", "c" } },
  },
  opts = {},
  config = function(_, opts)
    require("generate").setup(opts)
    vim.api.nvim_create_user_command("CppImpl", function(o)
      vim.cmd(o.range == 2
        and (o.line1 .. "," .. o.line2 .. "Generate implementations")
        or "Generate implementations")
    end, { range = true })
  end,
},
```

## :rocket: Usage

To generate method implementations simply run `:Generate implementations`
from the header file.

## Features

- Namespace-aware: declarations inside `namespace` blocks are wrapped in
  `namespace X { ... }  // namespace X` instead of using `X::` prefix
- Nested namespace support (`namespace a { namespace b { ... } }`)
- Class/struct method generation with proper `ClassName::` prefix
- Visual range selection — generate only selected declarations
- Automatic `#include` header insertion in source files
- Google brace style output
