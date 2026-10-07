local utils = require("config.utils")

-- lazydev (the lazydev provider) is added and loaded by plugins/lazydev.lua
return {
  "saghen/blink.cmp",
  enabled = not vim.g.mini.completion,
  build = utils.build_blink,
  dependencies = { "saghen/blink.lib", "fang2hou/blink-copilot" },
  event = { "InsertEnter", "CmdlineEnter" },
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
