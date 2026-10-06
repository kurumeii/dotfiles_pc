local add = require("config.deps").add

add({
  "nvim-lua/plenary.nvim",
  { source = "b0o/SchemaStore.nvim", lazy = true },
  { source = "justinsgithub/wezterm-types", lazy = true },
  { source = "folke/lazydev.nvim", lazy = true },
})

return {
  "lazydev.nvim",
  ft = "lua",
  before = function()
    -- lazydev resolves library paths from runtimepath
    vim.cmd.packadd("wezterm-types")
  end,
  after = function()
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        { path = "wezterm-types", words = { "wezterm" } },
      },
    })
  end,
}
