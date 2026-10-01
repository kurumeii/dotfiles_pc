require("config.deps").add({
  "mason-org/mason.nvim",
  "mason-org/mason-lspconfig.nvim",
  "WhoIsSethDaniel/mason-tool-installer.nvim",
})

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
  },
})

require("mason-lspconfig").setup({
  automatic_enable = {
    exclude = { "oxfmt" },
  },
})
