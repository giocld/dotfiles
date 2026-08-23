require("blink.cmp").setup {
  keymap = {
    preset = "default",
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
    ["<Enter>"] = { "select_and_accept", "fallback" },
    ["<C-l>"] = { "snippet_forward", "fallback" },
    ["<C-h>"] = { "snippet_backward", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
  },

  appearance = {
    use_nvim_cmp_as_default = false,
    nerd_font_variant = "normal",
  },

  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 100,
      window = {
        border = "rounded",
      },
    },
    menu = {
      border = "rounded",
      draw = {
        columns = {
          { "label", gap = 2, "kind_icon" },
          { gap = 2, "source_name", "label_description" },
        },
        components = {
          kind_icon = {
            text = function(ctx)
              return ctx.kind_icon
            end,
            highlight = function(ctx)
              return ctx.kind_hl
            end,
          },
          label = {
            width = { fill = true, max = 60 },
            text = function(ctx)
              return ctx.label .. ctx.label_detail
            end,
            highlight = function(ctx)
              return ctx.kind_hl
            end,
          },
          source_name = {
            width = { max = 30 },
            text = function(ctx)
              return ctx.source_name
            end,
            highlight = "BlinkCmpSource",
          },
        },
      },
    },
    accept = {
      auto_brackets = {
        enabled = true,
      },
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = { implementation = "prefer_rust_with_warning" },
  cmdline = {
    completion = {
      menu = {
        auto_show = true,
      },
    },
    keymap = {
      ["<Enter>"] = { "select_and_accept", "fallback" },
    },
  },
}

local nord_palette = {
  BlinkCmpKindText          = "#D8DEE9",
  BlinkCmpKindMethod        = "#8FBCBB",
  BlinkCmpKindFunction      = "#88C0D0",
  BlinkCmpKindConstructor   = "#5E81AC",
  BlinkCmpKindField         = "#81A1C1",
  BlinkCmpKindVariable      = "#D8DEE9",
  BlinkCmpKindClass         = "#5E81AC",
  BlinkCmpKindInterface     = "#5E81AC",
  BlinkCmpKindModule        = "#81A1C1",
  BlinkCmpKindProperty      = "#81A1C1",
  BlinkCmpKindUnit          = "#D8DEE9",
  BlinkCmpKindValue         = "#D8DEE9",
  BlinkCmpKindEnum          = "#B48EAD",
  BlinkCmpKindKeyword       = "#81A1C1",
  BlinkCmpKindSnippet       = "#A3BE8C",
  BlinkCmpKindColor         = "#D08770",
  BlinkCmpKindFile          = "#81A1C1",
  BlinkCmpKindReference     = "#81A1C1",
  BlinkCmpKindFolder        = "#81A1C1",
  BlinkCmpKindEnumMember    = "#B48EAD",
  BlinkCmpKindConstant      = "#EBCB8B",
  BlinkCmpKindStruct        = "#5E81AC",
  BlinkCmpKindEvent         = "#BF616A",
  BlinkCmpKindOperator      = "#81A1C1",
  BlinkCmpKindTypeParameter = "#B48EAD",
  BlinkCmpSource            = "#616E88",
  BlinkCmpLabel             = "#D8DEE9",
  BlinkCmpLabelMatch        = "#88C0D0",
}

for group, color in pairs(nord_palette) do
  vim.api.nvim_set_hl(0, group, { fg = color })
end
