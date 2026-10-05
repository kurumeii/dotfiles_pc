-- mini.hues generates the scheme from a background/foreground pair.
-- Base colors are Catppuccin Mocha; few hues + low saturation keep it muted.
require("mini.hues").setup({
  background = "#1e1e2e", -- base
  foreground = "#cdd6f4", -- text
  n_hues = 4,
  saturation = "medium",
  accent = "bg",
})
