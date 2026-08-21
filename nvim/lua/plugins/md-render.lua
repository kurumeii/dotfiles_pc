local add = require("mini.deps").add
local utils = require("config.utils")

add({
  source = "delphinus/md-render.nvim",
})

utils.map("n", utils.L("mp"), utils.C("MdRender toggle"), "Markdown preview (toggle)")
utils.map("n", utils.L("mt"), utils.C("MdRender tab"), "Markdown preview in tab")
