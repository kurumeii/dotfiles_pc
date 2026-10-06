vim.g.start_time = vim.uv.hrtime()

-- Must come before any vim.pack call: registers hooks and, via the lockfile,
-- vim.pack installs all locked plugins on its first call.
local deps = require("config.deps")
local later = deps.later

deps.add("nvim-mini/mini.nvim")
deps.add("lumen-oss/lz.n")

vim.g.noice = false
vim.g.mini = {
  tabline = false,
  animate = true,
  completion = false,
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
require("plugins.mini.basics")
require("plugins.mini.keymap")
require("plugins.mini.icons")
require("plugins.mini.sessions")
if vim.g.mini.clues then
  require("plugins.mini.clues")
end
require("plugins.mini.starter")
if vim.g.mini.colors then
  require("plugins.mini.colors")
end
if vim.g.mini.notify then
  require("plugins.mini.notify")
end
if vim.g.mini.explorer then
  require("plugins.mini.files")
end
if vim.g.mini.animate then
  require("plugins.mini.animate")
end
if vim.g.mini.input then
  require("plugins.mini.input")
end
if vim.g.mini.statuscolumn then
  require("plugins.mini.statuscolumn")
end
-- require("plugins.snacks")
later(function()
  -- Dev tooling
  require("plugins.lazydev")
  -- Typescript
  require("plugins.ts-autotag")
end)
later(function()
  -- LSP: mason first, then lspconfig
  require("plugins.mason")
  require("plugins.lspconfig")
end)
later(function()
  -- Linters
  require("plugins.nvim-lint")
  -- Format
  require("plugins.conform")
  -- Debugging
  require("plugins.dap")
end)
later(function()
  -- UI
  if vim.g.mini.tabline then
    require("plugins.mini.tabline")
  else
    require("plugins.bufferline")
  end
  if vim.g.mini.statusline then
    require("plugins.mini.statusline")
  else
    require("plugins.lualine")
  end

  require("plugins.nvim-navic")
  if vim.g.noice then
    require("plugins.noice")
  else
    require("plugins.ui2")
  end
end)
later(function()
  -- Misc
  require("plugins.nvim-ufo")
  -- require("plugins.sidekick")
  require("plugins.herdr_agent").setup()
  -- require("plugins.yazi")
  require("plugins.md-render")
  if not vim.g.mini.completion then
    require("plugins.blink")
  end
end)

-- Virtual specs (no package of their own) skip lz.n's :packadd.
local function noop() end

require("lz.n").load({
  require("plugins.colorschemes"),
  require("plugins.treesitter"),
  require("plugins.whichkey"),
  {
    "mini",
    event = "DeferredUIEnter",
    load = noop,
    after = function()
      -- Base minis: no config, no deps
      require("mini.bufremove").setup()
      require("mini.trailspace").setup()
      require("mini.move").setup()
      require("mini.fuzzy").setup()
      require("mini.bracketed").setup({
        treesitter = { suffix = "s" },
      })
      require("mini.extra").setup()

      -- Mini editing + display plugins (ai, hipatterns, picks use MiniExtra)
      require("plugins.mini.operators")
      require("plugins.mini.git")
      require("plugins.mini.ai")
      require("plugins.mini.jump")
      require("plugins.mini.surround")
      require("plugins.mini.snippets")
      if vim.g.mini.completion then
        require("plugins.mini.completion")
      end
      require("plugins.mini.cursorword")
      require("plugins.mini.pairs")
      require("plugins.mini.hipatterns")
      require("plugins.mini.misc")
      if vim.g.mini.picks then
        require("plugins.mini.picks")
      end
      require("plugins.mini.visits")
      require("plugins.mini.cmdline")
      if vim.g.mini.map then
        require("plugins.mini.map")
      end
      if vim.g.mini.indent then
        require("plugins.mini.indentscope")
      end
    end,
  },
  require("plugins.mini.comment"),
})
