-- Setup only: plugins/lspconfig.lua adds these plugins and requires this file
-- from its lz.n spec, after nvim-lspconfig is loaded.
require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

require("mason-tool-installer").setup({
  ensure_installed = {
    "tailwindcss",
    "vtsls",
    "lua_ls",
    "stylua",
    -- "cspell",
    "biome",
    "prettierd",
    "markdownlint-cli2",
    -- "oxfmt",
    -- "oxlint",
    "eslint-lsp",
    "css_variables",
    "cssls",
    "stylelint",
    "yamlfix",
    "jsonls",
    "yamlls",
    "taplo",
    "js-debug-adapter",
    "kdlfmt",
    "fish_lsp",
    "shfmt",
    "alejandra",
    "marksman",
  },
})

require("mason-lspconfig").setup({
  automatic_enable = {
    exclude = { "oxfmt" },
  },
})
