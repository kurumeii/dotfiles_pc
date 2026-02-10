local colorscheme = "gruvbox-material"
local transparent = false
local add = require("mini.deps").add

add("folke/tokyonight.nvim")
add("f4z3r/gruvbox-material.nvim")
add("ellisonleao/gruvbox.nvim")
add("rebelot/kanagawa.nvim")
add({ source = "catppuccin/nvim", name = "catppuccin" })
require("gruvbox").setup({
  contrast = "",
  transparent_mode = transparent,
})
add({
  source = "rose-pine/neovim",
  name = "rose-pine",
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
  integrations = {
    mini = {
      enabled = true,
      indentscope_color = "lavender",
    },
  },
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
