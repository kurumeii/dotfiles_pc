local MiniDeps = require("mini.deps")

MiniDeps.add({
  source = "Exafunction/codeium.nvim",
  depends = { "nvim-lua/plenary.nvim" },
})

require("codeium").setup({
  enable_cmp_source = false,
  virtual_text = {
    enabled = true,
    key_bindings = {
      accept = "<M-Tab>",
      accept_word = false,
      accept_line = true,
      clear = false,
      next = "<M-]>",
      prev = "<M-[>",
    },
  },
})
