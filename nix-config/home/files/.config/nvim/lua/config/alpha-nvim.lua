local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
            [[   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆          ]],
            [[    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ]],
            [[          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     ]],
            [[           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ]],
            [[          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ]],
            [[   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ]],
            [[  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ]],
            [[ ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ]],
            [[ ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ ]],
            [[      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ]],
            [[       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ]],
}


-- Set highlight colors for dashboard elements
vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#7aa2f7", bold = true })
vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#a9b1d6" })
vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = "#a9b1d6", bold = true })
vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#787c99", italic = true })

-- Apply highlight groups
dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.buttons.opts.hl = "AlphaButtons"
dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"
dashboard.section.footer.opts.hl = "AlphaFooter"

dashboard.section.buttons.val = {
  dashboard.button("f", "⨎  find file", "<cmd>FzfLua files<cr>"),
  dashboard.button("r", "⥁  recent", "<cmd>FzfLua oldfiles<cr>"),
  dashboard.button("g", "⟠  grep", "<cmd>FzfLua live_grep<cr>"),
  dashboard.button("c", "󰒓  confs", "<cmd>tabnew $MYVIMRC | tcd %:p:h<cr>"),
  dashboard.button("m", "⌨  mappings", "<cmd>edit ~/.config/nvim/lua/mappings.lua<cr>"),
  dashboard.button("b", "󰆹  bindings", "<cmd>FzfLua buffers<cr>"),
  dashboard.button("n", "󰍹  niri conf", "<cmd>edit ~/.config/niri/config.kdl<cr>"),
  dashboard.button("t", "󰌁  themes", "<cmd>lua require('colorschemes').rand_colorscheme()<cr>"),
}

dashboard.section.footer.val = { "", "Press q to quit", "" }

alpha.setup(dashboard.config)

-- Save theme to file for opencode sync
local function save_theme()
  local theme = vim.g.colors_name or "default"
  local opencode_tui = vim.fn.expand("~/.config/opencode/tui.json")
  local content = string.format('{"theme": "%s"}\n', theme)
  vim.fn.writefile({ content }, opencode_tui)
end

-- Custom statusline for alpha (dashboard) buffer
local function set_alpha_statusline()
  if vim.bo.filetype == "alpha" then
    local date = os.date("%d/%m/%y")
    local time = os.date("%H:%M")
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
    local theme = vim.g.colors_name or "default"
    vim.opt_local.statusline = " 󰉖 " .. cwd .. " │ 󰌁 " .. theme .. " %= " .. date .. " " .. time .. " "
  end
end

vim.api.nvim_create_autocmd({ "FileType", "Colorscheme" }, {
  callback = function()
    set_alpha_statusline()
    save_theme()
  end,
})

-- Keymaps for alpha buffer
vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function()
    vim.keymap.set("n", "f", "<cmd>FzfLua files<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "r", "<cmd>FzfLua oldfiles<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "g", "<cmd>FzfLua live_grep<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "c", "<cmd>tabnew $MYVIMRC | tcd %:p:h<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "m", "<cmd>edit ~/.config/nvim/lua/mappings.lua<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "b", "<cmd>FzfLua buffers<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "n", "<cmd>edit ~/.config/niri/config.kdl<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "t", "<cmd>lua require('colorschemes').rand_colorscheme()<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", ":qa<CR>", { buffer = true, silent = true })
  end,
})
