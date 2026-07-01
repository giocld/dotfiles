vim.g.rustaceanvim = {
  tools = {
    executor = require("rustaceanvim.executors").toggleterm,
    inlay_hints = {
      auto = true,
    },
  },
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.keymap.set("n", "<leader>rr", function() vim.cmd.RustLsp("run") end, { desc = "Run Rust code" })
    vim.keymap.set("n", "<leader>rt", function() vim.cmd.RustLsp("testables") end, { desc = "Run Rust tests" })
  end,
})
