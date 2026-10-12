return {
  "tiagovla/scope.nvim",
  after = function()
    require("scope").setup({})

    -- :checkhealth creates its (listed) buffer before `tab sbuffer`, so scope's TabLeave
    -- caches it under the old tab and TabNewEntered lists the old buffer in the new tab.
    -- Re-home the buffer to the tab that shows it.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "checkhealth",
      callback = function(ev)
        local core = require("scope.core")
        local tab = vim.api.nvim_get_current_tabpage()
        for t, bufs in pairs(core.cache) do
          core.cache[t] = vim.tbl_filter(function(b)
            return b ~= ev.buf
          end, bufs)
        end
        local normal_wins = vim.tbl_filter(function(w)
          return vim.api.nvim_win_get_config(w).relative == ""
        end, vim.api.nvim_tabpage_list_wins(tab))
        local fresh_tab = core.last_tab ~= 0 and core.last_tab ~= tab and core.cache[tab] == nil and #normal_wins == 1
        if fresh_tab then
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if b ~= ev.buf and vim.bo[b].buflisted then
              vim.bo[b].buflisted = false
            end
          end
        end
        vim.bo[ev.buf].buflisted = true
      end,
    })
  end,
}
