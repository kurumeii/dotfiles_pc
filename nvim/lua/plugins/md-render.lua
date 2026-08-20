local add = require("mini.deps").add
local utils = require("config.utils")

add({
  source = "delphinus/md-render.nvim",
  -- ponytail: skipping nvim-web-devicons/budoux.lua; plugin falls back to built-in icons & kinsoku rules
})

utils.map("n", utils.L("mp"), "<Plug>(md-render-preview)", "Markdown preview (toggle)")
utils.map("n", utils.L("mt"), "<Plug>(md-render-preview-tab)", "Markdown preview in tab")
utils.map("n", utils.L("md"), "<Plug>(md-render-demo)", "Markdown render demo")
