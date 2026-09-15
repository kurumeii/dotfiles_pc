---@module 'mini.deps'
MiniDeps.add("nvim-lualine/lualine.nvim")

local icons = mininvim.icons

local function get_copilot_status()
  if vim.fn.exists("*copilot#Enabled") == 1 and vim.fn["copilot#Enabled"]() == 1 then
    return icons.groups.copilot.glyph .. " "
  end
  return ""
end

require("lualine").setup({
  options = {
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    globalstatus = true,
  },
  sections = {
    lualine_a = {
      {
        "mode",
        fmt = function(str)
          return str:upper()
        end,
      },
    },
    lualine_b = {
      { "branch", icon = icons.git_branch },
      "diff",
      {
        "diagnostics",
        symbols = {
          error = icons.error,
          warn = icons.warn,
          info = icons.info,
          hint = icons.hint,
        },
      },
    },
    lualine_c = {
      {
        "filename",
        fmt = function()
          return vim.fn.expand("%:h:t") .. "/" .. vim.fn.expand("%:t")
        end,
        separator = { left = "", right = "" },
      },
    },
    lualine_x = {
      { "fileformat", symbols = { unix = icons.os.linux, dos = icons.os.win } },
      { "lsp_status", icon = icons.lsp },
      "filetype",
      "filesize",
    },
    lualine_y = { "filesize", "searchcount" },
    lualine_z = { "progress" },
  },
})
