return {
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  after = function()
    require("colorizer").setup({
      options = {
        display = {
          mode = "virtualtext",
          virtualtext = { char = "󰝤", position = "before" },
          disable_document_color = false, -- keep vim.lsp.document_color for tailwind
        },
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
