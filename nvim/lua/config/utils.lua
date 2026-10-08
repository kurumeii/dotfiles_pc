local H = {}

--- @param mode string | table<string> -- n, v, i, x
--- @param keys string
--- @param func function|string
--- @param desc? string
--- @param opts? vim.keymap.set.Opts
H.map = function(mode, keys, func, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set(mode, keys, func, opts)
end

H.L = function(key)
  return "<leader>" .. key
end
H.C = function(cmd)
  return "<cmd>" .. cmd .. "<cr>"
end

--- @param msg string
--- @param level? 'ERROR' | 'WARN' | 'INFO'
--- @param title string?
H.notify = function(msg, level, title)
  level = level or "INFO"
  vim.defer_fn(function()
    vim.notify(msg, vim.log.levels[level], { title = title or "Notification" })
  end, 1000)
end

--- @param msg string
--- @param level? 'ERROR' | 'WARN' | 'INFO'
--- @param title string?
H.notify_once = function(msg, level, title)
  level = level or "INFO"
  vim.notify_once(msg, vim.log.levels[level], { title = title or "Notification" })
end

--- @param ms integer the timeout in millisecond
--- @param fn function Callback function
H.debounce = function(ms, fn)
  local timer = vim.uv.new_timer()
  return function(...)
    local argv = { ... }
    if timer ~= nil then
      timer:start(ms, 0, function()
        timer:stop()
        vim.schedule_wrap(fn)(unpack(argv))
      end)
    end
  end
end

--- @param tbl table
--- Unique values from the input table
H.uniq = function(tbl)
  local seen, result = {}, {}
  for _, value in ipairs(tbl) do
    if not seen[value] then
      seen[value] = true
      result[#result + 1] = value
    end
  end
  return result
end

--- Build blink.cmp
--- @param params table Build parameters containing path
H.build_blink = function(params)
  local progress = { kind = "progress", source = "blink.cmp", title = "blink.cmp", status = "running" }
  -- like vim.pack: only the first/last report is kept in :messages history
  local function report(msg, history)
    progress.id = vim.api.nvim_echo({ { msg } }, history or false, progress)
    vim.cmd.redraw({ bang = true })
  end

  report("Building (cargo build --release)", true)
  local done, code, err, pending = false, nil, {}, ""
  local started, spawn_err = pcall(vim.system, { "cargo", "build", "--release" }, {
    cwd = params.path,
    text = true,
    stderr = function(_, data)
      if not data then
        return
      end
      err[#err + 1] = data
      -- chunks can end mid-line: only report complete "Compiling <crate> v<ver>" lines
      pending = pending .. data
      local lines = vim.split(pending, "[\r\n]+")
      pending = table.remove(lines)
      for i = #lines, 1, -1 do
        local crate = lines[i]:match("Compiling%s+(.+)")
        if crate then
          vim.schedule(function()
            report("Building: " .. crate)
          end)
          break
        end
      end
    end,
  }, function(obj)
    code = obj.code
    done = true
  end)
  if started then
    -- vim.wait (unlike SystemObj:wait) keeps scheduled callbacks and redraws running
    vim.wait(10 * 60 * 1000, function()
      return done
    end, 50)
  else
    err[#err + 1] = tostring(spawn_err)
  end

  -- blink.cmp v2 loads the library from <repo>/lib/*.so.<commit>, not target/release:
  -- its own build() (cargo is incremental here) moves the artifact there.
  if code == 0 then
    local ok, build_err = pcall(function()
      require("blink.cmp").build():pwait(60 * 1000)
    end)
    if not ok then
      code = 1
      err[#err + 1] = tostring(build_err)
    end
  end

  progress.status = code == 0 and "success" or "failed"
  if code == 0 then
    report("Build done", true)
  else
    report("Build failed (exit " .. tostring(code) .. ")", true)
    H.notify(table.concat(err):sub(-1000), "ERROR", "blink.cmp build")
  end
end

---@param dot_ext string
---@param target_ft string
H.set_ft = function(dot_ext, target_ft)
  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = "*." .. dot_ext,
    desc = "Set filetype to " .. target_ft,
    callback = function(args)
      vim.bo[args.buf].ft = target_ft
    end,
  })
end

---@param lsp_name string
---@return boolean
---Whether the LSP is active
H.has_lsp = function(lsp_name)
  local find_lsp = vim.lsp.get_clients({
    name = lsp_name,
    bufnr = vim.api.nvim_get_current_buf(),
  })
  return #find_lsp > 0
end

--- @param action lsp.CodeActionKind
H.action = function(action)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = {
        only = { action },
        diagnostics = {},
      },
    })
  end
end

---@param opts lsp.ExecuteCommandParams
---@param buffer? number
local execute = function(opts, buffer)
  vim.lsp.buf_request(buffer or 0, "workspace/executeCommand", {
    command = opts.command,
    arguments = opts.arguments,
  }, function(err)
    if err then
      H.notify(err.message, "ERROR")
    end
  end)
end

---@param command string
H.command = function(command)
  return function()
    execute({ command = command })
  end
end

---@param buf_id integer
---@param lhs string
---@param direction string
---@param close_on_file boolean
H.map_split = function(buf_id, lhs, direction, close_on_file)
  local MiniFiles = require("mini.files")
  local rhs = function()
    local new_target_window
    local cur_target_window = MiniFiles.get_explorer_state().target_window
    if cur_target_window ~= nil then
      vim.api.nvim_win_call(cur_target_window, function()
        vim.cmd("belowright " .. direction .. " split")
        new_target_window = vim.api.nvim_get_current_win()
      end)

      MiniFiles.set_target_window(new_target_window)
      MiniFiles.go_in({ close_on_file = close_on_file })
    end
  end

  local desc = "Open in " .. direction .. " split"
  if close_on_file then
    desc = desc .. " and close"
  end
  vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end

--- Deletes all listed buffers in a given direction from the current one silently.
--- @param direction 'left' | 'right'
H.delete_buffers_in_direction = function(direction)
  local listed_buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      table.insert(listed_buffers, bufnr)
    end
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_buf_idx
  for i, bufnr in ipairs(listed_buffers) do
    if bufnr == current_bufnr then
      current_buf_idx = i
      break
    end
  end

  if not current_buf_idx then
    return
  end

  if direction == "right" then
    if current_buf_idx == #listed_buffers then
      return
    end
    for i = #listed_buffers, current_buf_idx + 1, -1 do
      pcall(require("mini.bufremove").delete, listed_buffers[i], false)
    end
  elseif direction == "left" then
    if current_buf_idx == 1 then
      return
    end
    for i = current_buf_idx - 1, 1, -1 do
      pcall(require("mini.bufremove").delete, listed_buffers[i], false)
    end
  end
end

--- Get relative time string from timestamp
--- @param timestamp number Unix timestamp
H.get_relative_time = function(timestamp)
  local current_time = os.time()
  local diff = os.difftime(current_time, timestamp)
  local minutes = math.floor(diff / 60)
  local hours = math.floor(minutes / 60)
  local days = math.floor(hours / 24)

  if minutes < 1 then
    return "just now"
  elseif minutes < 60 then
    return string.format("%d mins ago", minutes)
  elseif hours < 24 then
    return string.format("%d hours ago", hours)
  elseif days <= 3 then
    return string.format("%d days ago", days)
  else
    return os.date("%m/%d/%Y", timestamp)
  end
end

--- @param state boolean
--- @param fs_entry table
H.toggle_dotfiles = function(state, fs_entry)
  if state then
    return true
  end
  return not vim.startswith(fs_entry.name, ".")
end

-- Central LSP config merger
---@overload fun(cfg: vim.lsp.ClientConfig): table                   -- global merge
---@overload fun(server: string, cfg: vim.lsp.ClientConfig): table    -- server specific merge
---@param a string|table
---@param b? table
H.setup_lsp = function(a, b)
  local server, cfg
  if type(a) == "string" then
    server, cfg = a, b or {}
  else
    server, cfg = "*", a or {}
  end
  _G.mininvim._lsp_configs = _G.mininvim._lsp_configs or { ["*"] = {} }
  vim.tbl_deep_extend("force", _G.mininvim._lsp_configs[server] or {}, cfg)
  vim.lsp.config(server, cfg)
end

--- Remove the common leading indent of the non-blank lines
--- @param lines string[]
local function dedent(lines)
  local indent = math.huge
  for _, l in ipairs(lines) do
    if l:find("%S") then
      indent = math.min(indent, #l:match("^%s*"))
    end
  end
  if indent == math.huge or indent == 0 then
    return lines
  end
  return vim.tbl_map(function(l)
    return l:sub(indent + 1)
  end, lines)
end

--- Rewrite vimdoc code blocks (">lua" ... "<") into markdown fences
--- @param lines string[]
--- @return string[]
H.vimdoc_to_fences = function(lines)
  local out, block = {}, nil
  local in_fence = false

  local function close()
    vim.list_extend(out, dedent(block))
    out[#out + 1] = "```"
    block = nil
  end

  for _, line in ipairs(lines) do
    local handled = false
    if block then
      local rest = line:match("^<(.*)$")
      if rest then
        close()
        if rest:find("%S") then
          out[#out + 1] = vim.trim(rest)
        end
        handled = true
      elseif line:find("^%S") then
        close() -- unindented text ends the block implicitly
      else
        block[#block + 1] = line
        handled = true
      end
    end

    if not handled then
      if line:find("^```") then
        in_fence = not in_fence
      elseif not in_fence then
        local prefix, lang = line:match("^(.-)%s>(%a*)$")
        if not prefix then
          prefix, lang = "", line:match("^>(%a*)$")
        end
        -- a bare trailing " >" in prose is not a block start
        if lang and (lang ~= "" or prefix == "" or prefix:find(":$")) then
          if prefix:find("%S") then
            out[#out + 1] = prefix
          end
          out[#out + 1] = "```" .. lang
          block = {}
          handled = true
        end
      end
      if not handled then
        out[#out + 1] = line
      end
    end
  end
  if block then
    close()
  end
  return out
end

--- Make LSP hover (K) highlight vimdoc code blocks (e.g. mini.nvim's ">lua")
H.patch_lsp_hover = function()
  local util = vim.lsp.util
  if util._vimdoc_fences_patched then
    return
  end
  local orig = util.convert_input_to_markdown_lines
  util.convert_input_to_markdown_lines = function(...)
    return H.vimdoc_to_fences(orig(...))
  end
  util._vimdoc_fences_patched = true
end

return H
