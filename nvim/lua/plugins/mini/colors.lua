local current_theme = {
  bg = "#1e1e2e",
  fg = "#cdd6f4",
}

require("mini.hues").setup({
  background = current_theme.bg,
  foreground = current_theme.fg,
  n_hues = 4,
  saturation = "medium",
})
