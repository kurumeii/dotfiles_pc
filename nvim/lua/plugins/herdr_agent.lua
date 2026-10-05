-- Agent side pane backed by herdr (replaces sidekick.nvim). Requires nvim to run inside herdr (HERDR_ENV=1).
local utils = require("config.utils")

local RATIO = 0.4 -- share of the width given to the agent pane
-- Each nvim lives in its own herdr pane; scope everything to it so several tabs/instances don't collide.
local SELF = vim.env.HERDR_PANE_ID
-- herdr agent names: lowercase letter first, then [a-z0-9_-], max 32 chars.
local NAME = ("nvim-agent-" .. (SELF or ""):gsub("[^%w]", "-")):lower():sub(1, 32)
local KINDS = { "claude", "codex", "opencode", "gemini", "cursor", "copilot", "pi", "amp", "kimi", "qwen" }

-- Tools herdr can't recognise as agents: run as a plain command in the pane (no lifecycle tracking).
local PLAIN = { ["command code"] = "cmdc", mimo = "mimo" }

local pane_id, last_kind

local function herdr(args)
  local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait()
  local ok, json = pcall(vim.json.decode, res.stdout or "")
  return res.code == 0, ok and json or nil, res.stderr
end

local function alive()
  if not pane_id then
    return false
  end
  local ok, json = herdr({ "pane", "get", pane_id })
  return ok and json ~= nil
end

local function pick_kind(cb)
  if last_kind then
    return cb(last_kind)
  end
  local installed = vim.tbl_filter(function(k)
    return vim.fn.executable(PLAIN[k] or k) == 1
  end, vim.list_extend(vim.deepcopy(KINDS), vim.tbl_keys(PLAIN)))
  vim.ui.select(installed, { prompt = "Agent" }, function(kind)
    if kind then
      last_kind = kind
      cb(kind)
    end
  end)
end

local function open(cb)
  if vim.env.HERDR_ENV ~= "1" or not SELF then
    return utils.notify("Not running inside herdr", "WARN", "Agent")
  end
  if alive() then
    return cb(pane_id)
  end
  pick_kind(function(kind)
    local ok, json, err = herdr({
      "pane", "split", SELF, "--direction", "right",
      "--ratio", tostring(1 - RATIO), "--cwd", vim.fn.getcwd(), "--no-focus",
    })
    if not ok or not json then
      return utils.notify("split failed: " .. (err or ""), "ERROR", "Agent")
    end
    pane_id = json.result.pane.pane_id
    local started, serr
    if PLAIN[kind] then
      started, _, serr = herdr({ "pane", "run", pane_id, PLAIN[kind] })
    else
      started, _, serr = herdr({ "agent", "start", NAME, "--kind", kind, "--pane", pane_id })
    end
    if not started then
      -- don't leave a dead pane behind that alive() would treat as the agent
      herdr({ "pane", "close", pane_id })
      pane_id = nil
      utils.notify("agent start failed: " .. (serr or ""), "ERROR", "Agent")
      return
    end
    cb(pane_id)
  end)
end

local function focus_agent()
  if not pane_id then
    return
  end
  if PLAIN[last_kind] then
    herdr({ "pane", "focus", "--pane", SELF, "--direction", "right" })
  else
    herdr({ "agent", "focus", pane_id })
  end
end

local function focus()
  open(focus_agent)
end

local function send(text)
  open(function(id)
    herdr({ "pane", "send-text", id, text })
    focus_agent()
  end)
end

local function relpath()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
end

local function selection()
  local mode = vim.fn.mode()
  if not mode:match("^[vV\22]") then
    return ("@%s:%d"):format(relpath(), vim.fn.line("."))
  end
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  local s, e = math.min(a, b), math.max(a, b)
  vim.api.nvim_feedkeys(vim.keycode("<esc>"), "nx", false)
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  return ("@%s:%d-%d\n```%s\n%s\n```\n"):format(relpath(), s, e, vim.bo.filetype, table.concat(lines, "\n"))
end

utils.map("n", utils.L("aa"), focus, "Agent: Open/Focus")
utils.map({ "x", "n" }, utils.L("as"), function()
  send(selection())
end, "Agent: Send Selection")
utils.map("n", utils.L("af"), function()
  send("@" .. relpath() .. " ")
end, "Agent: Send File")
utils.map("n", utils.L("ax"), function()
  if alive() then
    herdr({ "pane", "close", pane_id })
  end
  pane_id = nil
end, "Agent: Close")
