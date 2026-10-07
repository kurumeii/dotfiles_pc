local utils = require("config.utils")
local add = require("config.deps").add

add({
  "nvim-lua/plenary.nvim",
  "mikavilpas/yazi.nvim",
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
