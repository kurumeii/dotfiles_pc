return {
  "mini-input",
  virtual = true,
  enabled = vim.g.mini.input,
  priority = 940,
  after = function()
    local input = require("mini.input")

    input.setup({
      handlers = {
        -- Mimic snacks.input: floating box, middle-center, fixed width, centered title.
        view = input.gen_view.floatwin({
          style = "MM",
          adjust_config = function(_, config)
            config.title_pos = "center"
            config.width = math.min(60, vim.o.columns - 2)
            config.row = math.floor((vim.o.lines - vim.o.cmdheight - 3) / 2)
            config.col = math.floor((vim.o.columns - config.width - 2) / 2)
            return config
          end,
        }),
      },
    })
  end,
}
