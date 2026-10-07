return {
  "mini-colors",
  virtual = true,
  enabled = vim.g.mini.colors,
  priority = 980,
  after = function()
    local current_theme = {
      bg = "#1a1b26",
      fg = "#a9b1d6",
    }

    require("mini.hues").setup({
      background = current_theme.bg,
      foreground = current_theme.fg,
      n_hues = 6,
      -- saturation = "medium",
      -- accent = "bg",
    })
  end,
}
