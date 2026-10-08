return {
  "mason-org/mason.nvim",
  lazy = true,
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  after = function()
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
        "tsc",
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
        exclude = { "oxfmt", "vtsls" },
      },
    })
  end,
}
