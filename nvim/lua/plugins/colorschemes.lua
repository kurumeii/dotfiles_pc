local colorscheme = "catppuccin"
local transparent = false

local enabled = not vim.g.mini.colors
local plugins = {
  { source = "folke/tokyonight.nvim", lazy = true },
  { source = "f4z3r/gruvbox-material.nvim", lazy = true },
  { source = "ellisonleao/gruvbox.nvim", lazy = true },
  { source = "rebelot/kanagawa.nvim", lazy = true },
  { source = "catppuccin/nvim", name = "catppuccin", lazy = true },
  { source = "rose-pine/neovim", name = "rose-pine", lazy = true },
}
if enabled then
  require("config.deps").add(plugins)
end

return {
  "colorschemes",
  enabled = enabled,
  priority = 1000,
  -- Virtual spec: load every theme so any of them can be selected.
  load = function()
    for _, plugin in ipairs(plugins) do
      vim.cmd.packadd(plugin.name or plugin.source:match("[^/]+$"))
    end
  end,
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
