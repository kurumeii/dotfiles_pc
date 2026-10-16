return {
  "mini-statuscolumn",
  virtual = true,
  enabled = vim.g.mini.statuscolumn,
  priority = 930,
  after = function()
    local sc = require("mini.statuscolumn")

    vim.o.foldcolumn = "1"
    vim.o.signcolumn = "yes"
    vim.opt.fillchars:append({
      foldopen = mininvim.icons.fold.open,
      foldclose = mininvim.icons.fold.close,
      foldsep = " ",
      foldinner = " ",
    })

    -- %C draws folds with FoldColumn; give it Folded's fg (snacks-style icon color). fg only, Folded's bg would paint the whole gutter
    local folded_fg = vim.api.nvim_get_hl(0, { name = "Folded", link = false }).fg
    local cursorline_fg = vim.api.nvim_get_hl(0, { name = "CursorLineNr", link = false }).fg
    vim.api.nvim_set_hl(0, "FoldColumn", { fg = folded_fg })
    vim.api.nvim_set_hl(0, "CursorLineFold", { fg = cursorline_fg })

    sc.setup({
      content = sc.gen_content.main({
        { format = "s=lf", lnum = "%l ", sep = " " },
        { pos = "cursor", lnum = "%#CursorLineNr#%{printf('%3d ', v:lnum)}" },
        { ltype = "virt", lnum = "• " },
        { ltype = "wrap", lnum = "↳ " },
        { win = "inactive", sep = " " },
      }),
    })
  end,
}
