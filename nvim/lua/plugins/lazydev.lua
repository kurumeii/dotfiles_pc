return {
  "folke/lazydev.nvim",
  -- lazydev resolves library paths from runtimepath
  dependencies = { "justinsgithub/wezterm-types" },
  ft = "lua",
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
