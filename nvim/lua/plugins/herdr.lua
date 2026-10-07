-- Agent side pane backed by herdr (replaces sidekick.nvim). Requires nvim to run inside herdr (HERDR_ENV=1).
local utils = require("config.utils")

-- Where the agent pane opens ("right" or "down") and the share (0-1) of space it gets.
local config = {
  width = 0.4,
  direction = "right",
}
-- Each nvim lives in its own herdr pane; scope everything to it so several tabs/instances don't collide.
local SELF = vim.env.HERDR_PANE_ID
local KINDS = { "claude", "codex", "opencode", "gemini", "cursor", "copilot", "pi", "amp", "kimi", "qwen" }

-- Executable per picker entry when it differs from the label.
local EXE = { ["command code"] = "cmdc", mimo = "mimo" }

local TIMEOUT = 3000 -- ms; keep a hung herdr from freezing nvim
local STARTUP_DELAY = 1500 -- ms; let a fresh agent TUI come up before sending text

local pane_id, last_kind

local function herdr(args)
  local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait(TIMEOUT)
  local ok, json = pcall(vim.json.decode, res.stdout or "")
  return res.code == 0, ok and json or nil, res.stderr
end

-- The agent pane outlives nvim, so remember it on disk (keyed by our own herdr pane) and reattach next session.
local state_file = SELF and (vim.fn.stdpath("state") .. "/herdr_agent/" .. SELF:gsub("[^%w]", "_") .. ".json")

local function pane_info(id)
  local ok, json = herdr({ "pane", "get", id })
  return ok and json and vim.tbl_get(json, "result", "pane") or nil
end

local function forget()
  pane_id, last_kind = nil, nil
  if state_file then
    os.remove(state_file)
  end
end

local function remember()
  local info = pane_info(pane_id)
  if not (state_file and info) then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
  vim.fn.writefile(
    { vim.json.encode({ pane_id = pane_id, terminal_id = info.terminal_id, kind = last_kind }) },
    state_file
  )
end

-- Reattach to a saved agent pane. terminal_id guards against herdr having reused the pane id for something else.
local function restore()
  if not (state_file and vim.uv.fs_stat(state_file)) then
    return
  end
  local ok, saved = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_file), "\n"))
  local info = ok and type(saved) == "table" and pane_info(saved.pane_id) or nil
  if info and info.terminal_id == saved.terminal_id then
    pane_id, last_kind = saved.pane_id, saved.kind
  else
    forget()
  end
end

-- The agent runs as `cmd; exit`, so the pane closes when the agent quits; a live pane means a live agent.
local function alive()
  if not pane_id then
    restore()
  end
  if not pane_id then
    return false
  end
  if pane_info(pane_id) then
    return true
  end
  -- agent gone (or herdr errored): close best-effort so a live pane is never orphaned, then reset
  herdr({ "pane", "close", pane_id })
  forget()
  return false
end

local function pick_kind(cb)
  if last_kind then
    return cb(last_kind)
  end
  local extra = vim.tbl_keys(EXE)
  table.sort(extra)
  local installed = vim.tbl_filter(function(k)
    return vim.fn.executable(EXE[k] or k) == 1
  end, vim.list_extend(vim.deepcopy(KINDS), extra))
  if #installed == 0 then
    return utils.notify("No supported agent found in PATH", "ERROR", "Agent")
  end
  vim.ui.select(installed, { prompt = "Agent" }, function(kind)
    if kind then
      last_kind = kind
      cb(kind)
    end
  end)
end

local function open(cb)
  if vim.env.HERDR_ENV ~= "1" or not SELF then
    return utils.notify("Not running inside herdr", "ERROR", "Agent")
  end
  if alive() then
    return cb(pane_id)
  end
  pick_kind(function(kind)
    local ok, json, err = herdr({
      "pane",
      "split",
      SELF,
      "--direction",
      config.direction,
      "--ratio",
      tostring(1 - config.width),
      "--cwd",
      vim.fn.getcwd(),
      "--no-focus",
    })
    if not ok or not json then
      return utils.notify("split failed: " .. (err or ""), "ERROR", "Agent")
    end
    pane_id = vim.tbl_get(json, "result", "pane", "pane_id")
    if not pane_id then
      return utils.notify("split returned no pane id", "ERROR", "Agent")
    end
    local started, _, serr
    started, _, serr = herdr({ "pane", "run", pane_id, (EXE[kind] or kind) .. "; exit" })
    if not started then
      -- don't leave a dead pane behind that alive() would treat as the agent
      herdr({ "pane", "close", pane_id })
      pane_id = nil
      utils.notify("agent start failed: " .. (serr or ""), "ERROR", "Agent")
      return
    end
    remember()
    cb(pane_id, true)
  end)
end

local function focus_agent()
  if pane_id then
    herdr({ "pane", "focus", "--pane", SELF, "--direction", config.direction })
  end
end

local function focus()
  open(focus_agent)
end

local function send(text)
  open(function(id, fresh)
    local function go()
      herdr({ "pane", "send-text", id, text })
      focus_agent()
    end
    if fresh then
      vim.defer_fn(go, STARTUP_DELAY)
    else
      go()
    end
  end)
end

local function relpath()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fn.fnamemodify(name, ":.") or "[No Name]"
end

return {
  "herdr-agent",
  virtual = true,
  keys = {
    { utils.L("aa"), focus, desc = "Agent: Open/Focus" },
    {
      utils.L("as"),
      function()
        local mode = vim.fn.mode()
        if not mode:match("^[vV\22]") then
          return ("@%s:%d"):format(relpath(), vim.fn.line("."))
        end
        local a, b = vim.fn.line("v"), vim.fn.line(".")
        local s, e = math.min(a, b), math.max(a, b)
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "nx", false)
        local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
        send(lines)
      end,
      mode = { "x", "n" },
      desc = "Agent: Send Selection",
    },
    {
      utils.L("af"),
      function()
        send("@" .. relpath() .. " ")
      end,
      desc = "Agent: Send File",
    },
    {
      utils.L("ax"),
      function()
        if pane_id and not herdr({ "pane", "close", pane_id }) then
          return utils.notify("close failed", "ERROR", "Agent")
        end
        forget()
      end,
      desc = "Agent: Close",
    },
  },
}
