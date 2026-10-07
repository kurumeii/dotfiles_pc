-- Autocomplete is handled by blink.cmp (cmdline.enabled), keep only autocorrect + autopeek
require("mini.cmdline").setup({
  autocomplete = { enable = vim.g.mini.completion },
})
