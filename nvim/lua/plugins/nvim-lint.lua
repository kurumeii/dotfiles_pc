require("config.deps").add("mfussenegger/nvim-lint")
local lint = require("lint")
local cspell_util = require("config.lint.cspell")
local utils = require("config.utils")
local opts = {
  linters_by_ft = {
    markdown = { "markdownlint-cli2" },
    css = { "stylelint", "biome" },
    scss = { "stylelint", "biome" },
    javascriptreact = { "biome" },
    typescriptreact = { "biome" },
    typescript = { "biome" },
    javascript = { "biome" },
  },
  ---@type table<string,table>
  linters = {
    selene = {
      condition = function(ctx)
        return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
      end,
    },
  },
}
for name, linter in ipairs(opts.linters) do
  if type(linter) == "table" and type(lint.linters[name]) == "table" then
    lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
    if type(linter.prepend_args) == "table" then
      lint.linters[name].args = lint.linters[name].args or {}
      vim.list_extend(lint.linters[name].args, linter.prepend_args)
    end
  else
    lint.linters[name] = linter
  end
end
lint.linters_by_ft = opts.linters_by_ft
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
  callback = utils.debounce(200, function()
    -- Skip scratch/special buffers (LSP hover floats, prompts, terminals)
    if vim.bo.buftype ~= "" then
      return
    end
    local names = lint._resolve_linter_by_ft(vim.bo.ft)
    names = vim.deepcopy(names)
    if #names == 0 then
      vim.list_extend(names, lint.linters_by_ft["_"] or {})
    end
    vim.list_extend(names, lint.linters_by_ft["*"] or {})
    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    names = vim.tbl_filter(function(name)
      local linter = lint.linters[name]
      if not linter then
        utils.notify_once("Linter not found: " .. name, "ERROR", "nvim-lint")
      end
      ---@diagnostic disable-next-line: undefined-field
      return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, names)

    if #names > 0 then
      lint.try_lint(names)
    end
  end),
})
local cspell_config_file = cspell_util.config_path()
if cspell_config_file then
  lint.linters_by_ft = {
    ["*"] = { "cspell" },
  }
  lint.linters.cspell = function()
    local default_config = require("lint.linters.cspell")
    local config = vim.deepcopy(default_config)
    config.args = {
      "lint",
      "--no-color",
      "--no-progress",
      "--no-summary",
      type(cspell_config_file) == "string" and "--config=" .. cspell_config_file or "",
      function()
        return "stdin://" .. vim.api.nvim_buf_get_name(0)
      end,
    }
    return config
  end
end
