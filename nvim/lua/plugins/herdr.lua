return {
  "herdr-agent",
  virtual = true,
  event = "DeferredUIEnter",
  after = function()
    require("config.herdr_agent").setup()
  end,
}
