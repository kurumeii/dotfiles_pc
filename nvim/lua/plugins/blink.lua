local utils = require("config.utils")
local enabled = not vim.g.mini.completion
if enabled then
  -- lazydev (the lazydev provider) is added and loaded by plugins/lazydev.lua
  require("config.deps").add({
    { source = "saghen/blink.lib", lazy = true },
    { source = "fang2hou/blink-copilot", lazy = true },
    {
      source = "saghen/blink.cmp",
      lazy = true,
      hooks = {
        post_checkout = utils.build_blink,
        post_install = utils.build_blink,
      },
    },
  })
end

return {
  "blink.cmp",
  enabled = enabled,
  event = { "InsertEnter", "CmdlineEnter" },
  before = function()
    vim.cmd.packadd("blink.lib")
    vim.cmd.packadd("blink-copilot")
  end,
  after = function()
    require("blink.cmp").setup({
      keymap = {
        preset = "enter",
      },
      appearance = {
        nerd_font_variant = "normal",
      },
      completion = {
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = false, -- README: Should work with AI autocomplete
        },
        menu = {
          draw = {
            columns = {
              { "label", gap = 1 },
              { "kind_icon", "kind", "label_description", gap = 1 },
            },
            treesitter = { "lsp" },
            components = {
              kind_icon = {
                text = function(ctx)
                  local kind_icon, _, _ = MiniIcons.get("lsp", ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = MiniIcons.get("lsp", ctx.kind)
                  return hl
                end,
              },
              kind = {
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = MiniIcons.get("lsp", ctx.kind)
                  return hl
                end,
              },
            },
          },
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            async = true,
          },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function()
              return vim.fn.getcmdtype() == ":"
            end,
          },
          ghost_text = { enabled = true },
        },
      },
      snippets = { preset = "mini_snippets" },
      fuzzy = {
        implementation = "prefer_rust",
        sorts = {
          "exact",
          -- defaults
          "score",
          "sort_text",
        },
      },
      signature = {
        enabled = true,
        window = {
          show_documentation = false,
        },
      },
    })
  end,
}
