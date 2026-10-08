return {
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  after = function()
    require("colorizer").setup({
      options = {
        parsers = {
          hex = { default = false, rgb = true, rgba = true },
          rgb = { enable = true },
          hsl = { enable = true },
          oklch = { enable = true },
          css_var = { enable = true, parsers = { css = true } },
          names = { enable = false },
          tailwind = {
            enable = true,
            lsp = { enable = true },
            update_names = true,
          },
        },
      },
    })
  end,
}
