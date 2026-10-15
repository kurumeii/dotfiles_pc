local utils = require("config.utils")
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      utils.L("cf"),
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format buffer",
    },
  },
  after = function()
    require("conform").setup({
      notify_on_error = false,
      default_format_opts = {
        timeout_ms = 1000,
        lsp_format = "fallback",
        stop_after_first = true,
      },
      -- Sync on BufWritePre: one write per save (async format_after_save
      -- re-writes the file, doubling every "Saved" notification).
      format_on_save = {},
      formatters_by_ft = {
        markdown = { "markdownlint-cli2", "prettierd" },
        lua = { "stylua" },
        json = { "biome" },
        yaml = { "yamlfix" },
        javascript = { "biome", "prettierd" },
        typescript = { "biome", "prettierd" },
        typescriptreact = { "biome", "prettierd" },
        javascriptreact = { "biome", "prettierd" },
        css = { "biome", "prettierd" },
        scss = { "biome", "prettierd" },
        kdl = { "kdlfmt" },
        sh = { "shfmt" },
        nix = { "alejandra" },
      },
      formatters = {
        biome = {
          require_cwd = true,
        },
        stylua = {},
        yamlfix = {},
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then
                return true
              end
              return false
            end
          end,
        },
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
      },
    })
  end,
}
