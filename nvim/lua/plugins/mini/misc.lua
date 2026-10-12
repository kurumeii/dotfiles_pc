local MiniMisc = require("mini.misc")
MiniMisc.setup()
MiniMisc.setup_restore_cursor()
MiniMisc.setup_auto_root()
-- WezTerm doesn't support OSC 111 reset; restore by writing back the captured color instead
MiniMisc.setup_termbg_sync({ explicit_reset = true })
