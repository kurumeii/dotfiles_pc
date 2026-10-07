vim.g.start_time = vim.uv.hrtime()

-- Must come before any vim.pack call: registers hooks and, via the lockfile,
-- vim.pack installs all locked plugins on its first call.
local deps = require("config.deps")

deps.add("nvim-mini/mini.nvim")

vim.g.noice = false
vim.g.mini = {
  tabline = true,
  animate = true,
  completion = true,
  picks = true,
  show_dotfiles = true,
  notify = true,
  indent = true,
  explorer = true,
  statusline = true,
  clues = true,
  map = true,
  input = true,
  statuscolumn = true,
  colors = true,
}

require("config.options")
require("config.keymaps")
require("config.mininvim")
require("config.autocmds")

deps.setup({ import = "plugins" })
