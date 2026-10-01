local add = require("config.deps").add

add({
  "b0o/SchemaStore.nvim",
  "nvim-lua/plenary.nvim",
  "justinsgithub/wezterm-types",
  "folke/lazydev.nvim",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  callback = function()
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        { path = "wezterm-types", words = { "wezterm" } },
      },
    })
  end,
})
