local utils = require("config.utils")
local add = require("mini.deps").add

add({
  source = "mikavilpas/yazi.nvim",
  depends = { "nvim-lua/plenary.nvim" },
})

require("yazi").setup({
  open_for_directories = true,
  floating_window_scaling_factor = 0.9,
  yazi_floating_window_border = "rounded",
  keymaps = {
    show_help = "<f1>",
  },
})

utils.map("n", utils.L("ty"), "<cmd>Yazi<cr>", "Open yazi at current file")
utils.map("n", utils.L("tY"), "<cmd>Yazi cwd<cr>", "Open yazi at cwd")
