return {
  "delphinus/md-render.nvim",
  ft = "markdown",
  cmd = "MdRender",
  keys = {
    { "<leader>mp", "<cmd>MdRender toggle<cr>", desc = "Markdown preview (toggle)" },
    { "<leader>mt", "<cmd>MdRender tab<cr>", desc = "Markdown preview in tab" },
  },
}
