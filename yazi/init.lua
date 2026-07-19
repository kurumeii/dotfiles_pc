require("yamb"):setup {}

require("full-border"):setup { type = ui.Border.ROUNDED }

require("omp"):setup {
	config = (ya.target_family() == "windows" and os.getenv("USERPROFILE") .. "\\andrew.omp.json")
		or (os.getenv("HOME") .. "/andrew.omp.json"),
}
