-- Specs for the mini.nvim modules in this directory (picked up by `import = "plugins"`).
-- The other files here are plain modules required from these specs or from init.lua.
return {
  -- Eager and always on, in this order (priority): they must run before the first draw
  require("plugins.mini.basics"),
  require("plugins.mini.keymap"),
  require("plugins.mini.icons"),
  require("plugins.mini.sessions"),
  require("plugins.mini.starter"),
  -- Eager, toggled by vim.g.mini
  require("plugins.mini.clues"),
  require("plugins.mini.colors"),
  require("plugins.mini.notify"),
  require("plugins.mini.files"),
  require("plugins.mini.animate"),
  require("plugins.mini.input"),
  require("plugins.mini.statuscolumn"),
  {
    "mini",
    virtual = true,
    event = "DeferredUIEnter",
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
  {
    "mini-ui",
    virtual = true,
    event = "DeferredUIEnter",
    before = function()
      -- tabline maps MiniBufremove, which the "mini" spec sets up
      require("lz.n").trigger_load("mini")
    end,
    after = function()
      if vim.g.mini.tabline then
        require("plugins.mini.tabline")
      end
      if vim.g.mini.statusline then
        require("plugins.mini.statusline")
      end
    end,
  },
}
