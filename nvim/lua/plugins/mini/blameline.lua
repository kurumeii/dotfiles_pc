-- Inline git blame for the cursor line, shown as virtual text on CursorHold.
-- Relies on mini.git for the repository root.
local utils = require("config.utils")

local M = {}

---@class blameline.Config
---@field enabled boolean Show blame on CursorHold
---@field uncommitted_text string Text shown for lines not committed yet
---@field format string Template, see the placeholder list above `defaults`
---@field date_format string `os.date` format used by {date} and {committer_date}

---@class blameline.Opts
---@field enabled? boolean Show blame on CursorHold
---@field uncommitted_text? string Text shown for lines not committed yet
---@field format? string Template, see the placeholder list above `defaults`
---@field date_format? string `os.date` format used by {date} and {committer_date}

-- Placeholders available in `format`:
--   {hash} {short_hash} {summary} {filename}
--   {author} {author_mail} {date} {rel_time}
--   {committer} {committer_mail} {committer_date} {committer_rel_time}
---@type blameline.Config
local defaults = {
  enabled = true,
  uncommitted_text = "  Not committed yet",
  format = " ({rel_time}) {author} -> {summary}",
  date_format = "%Y-%m-%d",
}

---@type blameline.Config
local config = vim.deepcopy(defaults)
local ns_id = vim.api.nvim_create_namespace("Blameline")

--- Remove the blame annotation from a buffer.
---@param buf? integer Buffer handle, defaults to the current buffer
function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf or 0, ns_id, 0, -1)
end

---@param buf integer
---@param line integer 1-based line number
---@param text string
local function set_text(buf, line, text)
  vim.api.nvim_buf_set_extmark(buf, ns_id, line - 1, 0, {
    virt_text = { { text, "Comment" } },
    hl_mode = "combine",
  })
end

--- Run `git blame` for the cursor line and show the result as virtual text.
local function show()
  if not config.enabled then
    return
  end
  M.clear()
  if not MiniGit then
    return
  end
  local buf_data = MiniGit.get_buf_data(0)
  if not buf_data or not buf_data.root then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%")
  local line = vim.fn.line(".")
  local cmd = { "git", "-C", buf_data.root, "blame", "-L", string.format("%d,%d", line, line), "--porcelain", file }

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      -- If we moved away, don't show stale blame
      if vim.api.nvim_get_current_buf() ~= buf or vim.api.nvim_win_get_cursor(0)[1] ~= line then
        return
      end
      local output = obj.stdout
      if obj.code ~= 0 or not output or output == "" then
        return
      end

      local hash = output:match("^(%S+)")
      if not hash then
        return
      end
      if hash:match("^0+$") then
        set_text(buf, line, config.uncommitted_text)
        return
      end

      -- Porcelain header: "<key> <value>" lines until the tab-prefixed source line
      ---@type table<string, string>
      local fields = {}
      for key, value in output:gmatch("\n([%w%-]+) ([^\n]*)") do
        fields[key] = value
      end
      local time = tonumber(fields["author-time"])
      local committer_time = tonumber(fields["committer-time"])
      if not (fields.author and fields.summary and time and committer_time) then
        return
      end

      ---@type table<string, string>
      local info = {
        hash = hash,
        short_hash = hash:sub(1, 7),
        summary = fields.summary,
        filename = fields.filename or "",
        author = fields.author,
        author_mail = fields["author-mail"] or "",
        date = os.date(config.date_format, time) --[[@as string]],
        rel_time = utils.get_relative_time(time) --[[@as string]],
        committer = fields.committer or "",
        committer_mail = fields["committer-mail"] or "",
        committer_date = os.date(config.date_format, committer_time) --[[@as string]],
        committer_rel_time = utils.get_relative_time(committer_time) --[[@as string]],
      }
      set_text(buf, line, (config.format:gsub("{([%w_]+)}", info)))
    end)
  end)
end

--- Enable blame annotations.
function M.enable()
  config.enabled = true
end

--- Disable blame annotations and clear the current one.
function M.disable()
  config.enabled = false
  M.clear()
end

--- Toggle blame annotations and notify the new state.
function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
  local msg = config.enabled and "Blame annotations enabled" or "Blame annotations disabled"
  utils.notify(msg, "INFO", "Git")
end

--- Merge options with the defaults and create the autocommands.
---@param opts? blameline.Opts
function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  local group = vim.api.nvim_create_augroup("Blameline", { clear = true })
  vim.api.nvim_create_autocmd("CursorHold", { group = group, callback = show })
  -- Clear blame immediately when moving
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = group,
    callback = function()
      M.clear()
    end,
  })
end

return M
