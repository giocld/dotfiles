require("nvim-treesitter").setup {
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
      },
      selection_modes = {
        ["@function.inner"] = "V",
        ["@function.outer"] = "V",
        ["@class.outer"] = "V",
        ["@class.inner"] = "V",
        ["@parameter.outer"] = "v",
      },
      include_surrounding_whitespace = false,
    },
  },
}
