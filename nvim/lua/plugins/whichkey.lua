---@module 'mini.deps'
MiniDeps.add("folke/which-key.nvim")

local wk = require("which-key")

wk.setup({
  preset = "helix",
  win = {
    col = 0,
    row = -1,
  },
  plugins = {
    marks = true,
    registers = true,
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      z = true,
      g = true,
    },
  },
})

wk.add({
  { "<leader>a",  group = "Agents" },
  { "<leader>b",  group = "Buffers" },
  { "<leader>c",  group = "Code" },
  { "<leader>cs", group = "Code spell" },
  { "<leader>d",  group = "Debugger" },
  { "<leader>f",  group = "Find" },
  { "<leader>g",  group = "Git" },
  { "<leader>l",  group = "Lsp" },
  { "<leader>o",  group = "MiniOperators", mode = { "n", "x", "i" } },
  { "<leader>n",  group = "Notify" },
  { "<leader>s",  group = "Sessions" },
  { "<leader>p",  group = "Package" },
  { "<leader>t",  group = "Terminal" },
  { "<leader>w",  group = "Window" },
})
