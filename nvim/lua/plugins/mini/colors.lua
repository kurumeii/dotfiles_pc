return {
  "mini-colors",
  virtual = true,
  enabled = vim.g.mini.colors,
  priority = 980,
  after = function()
    local current_theme = {
      bg = "#15161e",
      fg = "#c0caf5",
    }

    require("mini.hues").setup({
      background = current_theme.bg,
      foreground = current_theme.fg,
      n_hues = 6,
      saturation = "mediumhigh",
      accent = "bg",
    })
  end,
}
