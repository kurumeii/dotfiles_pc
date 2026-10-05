local utils = require("config.utils")
local MiniMap = require("mini.map")
MiniMap.setup({
  symbols = {
    -- Blank content: only scroll_line/scroll_view are visible
    encode = { " ", " ", resolution = { row = 1, col = 1 } },
    scroll_line = mininvim.icons.map.scroll_line,
    scroll_view = mininvim.icons.map.scroll_view,
  },
  window = {
    width = 1,
    focusable = false,
    show_integration_count = false,
  },
})

local dashboards = { ministarter = true, snacks_dashboard = true, alpha = true, dashboard = true }
local pending_open = true

local function sync()
  if dashboards[vim.bo.filetype] then
    MiniMap.close()
    pending_open = true
  elseif vim.bo.buftype == "" then
    local fits = vim.api.nvim_win_text_height(0, {}).all <= vim.api.nvim_win_get_height(0)
    if fits then
      MiniMap.close()
      pending_open = true
    elseif pending_open then
      MiniMap.open()
      pending_open = false
    end
  end
end
vim.api.nvim_create_autocmd(
  { "BufEnter", "FileType", "TextChanged", "InsertLeave", "WinResized", "VimResized" },
  { callback = vim.schedule_wrap(sync) }
)
-- Starter sets its filetype without autocmds, so hook its own event too
vim.api.nvim_create_autocmd("User", { pattern = "MiniStarterOpened", callback = sync })
sync()

utils.map("n", utils.L("mm"), MiniMap.toggle, "Toggle minimap")
