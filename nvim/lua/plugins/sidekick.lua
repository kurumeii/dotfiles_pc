MiniDeps.add("folke/sidekick.nvim")
local utils = require("config.utils")

-- ponytail: sidekick passes exepath() straight to CreateProcess unresolved; dereference symlinks ourselves.
local function resolve_cmd(name)
  local path = vim.fn.exepath(name)
  if path == "" then
    return { name }
  end
  return { vim.uv.fs_realpath(path) or path }
end

local agent_tools = {}
for name in pairs(require("sidekick.config").cli.tools) do
  agent_tools[name] = { cmd = resolve_cmd(name) }
end

-- AGENT
require("sidekick").setup({
  nes = {
    enabled = false,
    debounce = 200,
    diff = {
      inline = "words",
    },
  },
  cli = {
    tools = agent_tools,
    ---@type sidekick.win.Opts
    win = {
      layout = "right",
      split = {
        width = 80,
      },
      keys = {
        prompt = { "<c-]>", "prompt" },
      },
    },
  },
})

local sk_cli = require("sidekick.cli")
local get_installed = { installed = true }

utils.map("n", utils.L("aa"), function()
  sk_cli.toggle({ filter = get_installed })
end, "Agent: Toggle")
utils.map({ "x", "n" }, utils.L("as"), function()
  sk_cli.send({ msg = "{this}", filter = get_installed })
end, "Agent: Send Selection")
utils.map("n", utils.L("af"), function()
  sk_cli.send({ msg = "{file}", filter = get_installed })
end, "Agent: Send File")
utils.map("n", "<s-tab>", function()
  require("sidekick.nes").apply()
end, "Goto/Apply NES", { expr = true })
