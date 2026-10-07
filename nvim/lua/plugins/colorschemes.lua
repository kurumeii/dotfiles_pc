local colorscheme = "catppuccin"
local transparent = false

return {
  "colorschemes",
  enabled = not vim.g.mini.colors,
  priority = 1000,
  -- Virtual spec: its dependencies are all themes, loaded so any can be selected.
  virtual = true,
  dependencies = {
    "folke/tokyonight.nvim",
    "f4z3r/gruvbox-material.nvim",
    "ellisonleao/gruvbox.nvim",
    "rebelot/kanagawa.nvim",
    { "catppuccin/nvim", name = "catppuccin" },
    { "rose-pine/neovim", name = "rose-pine" },
  },
  after = function()
    require("gruvbox").setup({
      contrast = "",
      transparent_mode = transparent,
    })
    require("gruvbox-material").setup({
      background = {
        transparent = transparent,
      },
    })
    require("kanagawa").setup({
      theme = "dragon",
      dimInactive = true,
    })
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = transparent,
      auto_integrations = true,
    })
    require("tokyonight").setup({
      style = "night",
      transparent = transparent,
      lualine_bold = true,
    })
    require("rose-pine").setup({
      dark_variant = "moon",
      styles = {
        transparency = transparent,
      },
    })

    if colorscheme == "mini" then
      vim.cmd.colorscheme("miniwinter")
    else
      vim.cmd.colorscheme(colorscheme)
    end
  end,
}
