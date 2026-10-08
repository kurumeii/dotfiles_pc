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
