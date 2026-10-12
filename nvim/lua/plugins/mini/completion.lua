local MiniCompletion = require("mini.completion")
local utils = require("config.utils")

local cache = require("config.cache").new()

--- Cached responses of all completion clients, or nil on any miss
local function lookup(bufnr, method, key, col)
  local hit = nil
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = method })) do
    local value = cache:get(client.id, key, col)
    if value == nil then
      return nil
    end
    hit = hit or {}
    hit[client.id] = value
  end
  return hit
end

utils.wrap(vim.lsp, "buf_request_all", function(request_all, bufnr, method, params, handler)
  if method ~= "textDocument/completion" then
    return request_all(bufnr, method, params, handler)
  end

  -- Same context = same buffer + line + text before the current word ('iskeyword', like mini)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local before = vim.api.nvim_get_current_line():sub(1, col)
  local key = bufnr .. ":" .. row .. ":" .. before:sub(1, vim.fn.match(before, "\\k*$"))

  local hit = lookup(bufnr, method, key, col)
  if hit then
    local cancelled = false
    vim.schedule(function()
      if not cancelled then
        handler(vim.deepcopy(hit)) -- mini mutates items
      end
    end)
    return function()
      cancelled = true
    end
  end

  return request_all(bufnr, method, params, function(result, ...)
    for id, value in pairs(result) do
      if value.result ~= nil then
        cache:set(id, key, col, value)
      end
    end
    return handler(result, ...)
  end)
end)
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    cache:clear()
  end,
})

MiniCompletion.setup({
  delay = { completion = 100, info = 100, signature = 50 },
  -- LSP items only: the keyword fallback made results inconsistent
  fallback_action = function() end,
  mappings = {
    scroll_down = "<c-f>",
    scroll_up = "<c-b>",
  },
  lsp_completion = {
    source_func = "omnifunc",
    process_items = function(items, base)
      table.sort(items, function(a, b)
        return (a.sortText or a.label) < (b.sortText or b.label)
      end)
      local res = MiniCompletion.default_process_items(items, base, { filtersort = "fuzzy" })
      local exact, rest = {}, {}
      for _, item in ipairs(res) do
        local text = item.filterText or item.label
        table.insert(text == base and exact or rest, item)
      end
      return vim.list_extend(exact, rest)
    end,
  },
})

-- Force noinsert so cycling through the menu doesn't override current text
vim.opt.completeopt = { "menuone", "noinsert", "noselect" }
