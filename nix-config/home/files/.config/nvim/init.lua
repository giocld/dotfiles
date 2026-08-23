vim.loader.enable()

-- python provider (pynvim) via the stable wrapper deployed by home-manager
vim.g.python3_host_prog = os.getenv("HOME") .. "/.local/bin/nvim-python3"

local utils = require("utils")

local expected_version = "0.11.6"
utils.is_compatible_version(expected_version)

local config_dir = vim.fn.stdpath("config")
---@cast config_dir string

-- some global settings
require("globals")
-- setting options in nvim
vim.cmd("source " .. vim.fs.joinpath(config_dir, "viml_conf/options.vim"))
-- various autocommands
require("custom-autocmd")
-- all the user-defined mappings
require("mappings")

-- all the plugins installed and their configurations
require("plugin_specs")

-- diagnostic related config
require("diagnostic-conf")

-- colorscheme settings
local color_scheme = require("colorschemes")
vim.cmd.colorscheme("vague")

-- Custom cursor and highlight colors
local custom_hl_group = vim.api.nvim_create_augroup("CustomHighlights", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = custom_hl_group,
  callback = function()
    vim.api.nvim_set_hl(0, "Cursor", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "CursorIM", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "Visual", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "HighlightedyankRegion", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyPut", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyYanked", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "IncSearch", { bg = "#86bece", fg = "#000000" })
    vim.api.nvim_set_hl(0, "Search", { bg = "#86bece", fg = "#000000" })
    vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor"
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  group = custom_hl_group,
  callback = function()
    vim.api.nvim_set_hl(0, "Cursor", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "CursorIM", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "Visual", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "HighlightedyankRegion", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyPut", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyYanked", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "IncSearch", { bg = "#86bece", fg = "#000000" })
    vim.api.nvim_set_hl(0, "Search", { bg = "#86bece", fg = "#000000" })
    vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor"
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = custom_hl_group,
  callback = function()
    vim.api.nvim_set_hl(0, "Cursor", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "CursorIM", { bg = "#86bece", fg = "NONE" })
    vim.api.nvim_set_hl(0, "Visual", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "HighlightedyankRegion", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyPut", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyYanked", { bg = "#86bece" })
    vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor"
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = custom_hl_group,
  callback = function()
    vim.api.nvim_set_hl(0, "HighlightedyankRegion", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyPut", { bg = "#86bece" })
    vim.api.nvim_set_hl(0, "YankyYanked", { bg = "#86bece" })
  end,
})
