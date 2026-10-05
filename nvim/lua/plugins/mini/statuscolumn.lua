local sc = require("mini.statuscolumn")

vim.o.foldcolumn = "1"
vim.o.signcolumn = "auto:1-2"
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
