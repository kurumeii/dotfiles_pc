local hi = require("mini.hipatterns")
local hi_words = MiniExtra.gen_highlighter.words
hi.setup({
	highlighters = {
		fixme = hi_words({ "FIXME", "fixme" }, "MiniHiPatternsFixme"),
		todo = hi_words({ "TODO", "todo" }, "MiniHiPatternsTodo"),
		note = hi_words({ "NOTE", "note", "readme", "README" }, "MiniHiPatternsNote"),
		bug = hi_words({ "BUG", "bug", "HACK", "hack", "hax" }, "MiniHiPatternsHack"),
		hex_color = hi.gen_highlighter.hex_color({ priority = 200 }),
	},
})
