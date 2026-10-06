-- Thin plugin-manager helper on top of Neovim's built-in `vim.pack`.
-- Mimics the add/now/later API of the old deps manager used by this config:
--   add(spec | { spec, ... }), spec = string | { source, name, checkout, hooks, lazy }, now(f), later(f)
-- A spec with `lazy = true` is installed and registered but not loaded; lz.n
-- loads it later with :packadd.
-- Lockfile: $XDG_CONFIG_HOME/nvim/nvim-pack-lock.json (tracked in dotfiles).
-- When it exists, vim.pack installs every plugin in it at the locked revision
-- on the first vim.pack call, so require this module BEFORE any vim.pack.add.
local M = {}

M.config = { confirm = false }

local hooks = {} -- [plugin name] = { post_install = fn, post_checkout = fn }
local seen = {} -- [plugin name] = true
local queue, draining = {}, false

local function safely(label, f, ...)
  local ok, err = xpcall(f, debug.traceback, ...)
  if not ok then
    vim.notify(("(deps) Error in %s: %s"):format(label, err), vim.log.levels.ERROR)
  end
end

local function normalize(spec)
  if type(spec) == "string" then
    spec = { source = spec }
  end
  local source = spec.source
  if not source:find("://", 1, true) and not source:find("^git@") then
    source = "https://github.com/" .. source
  end
  local version = spec.checkout
  if version == "HEAD" then
    version = nil
  end
  return {
    src = source,
    name = spec.name or (source:gsub("/+$", ""):match("([^/]+)$"):gsub("%.git$", "")),
    version = version,
  }
end

local function run_hook(fn, data)
  if not data.active then
    pcall(vim.cmd.packadd, data.spec.name)
  end
  safely("hook " .. data.spec.name, fn, { path = data.path, source = data.spec.src, name = data.spec.name })
end

local function run_hooks(h, kind, data)
  -- A fresh install runs post_install, or post_checkout when there is no
  -- post_install, so a build hook given for both is not run twice.
  if kind == "install" then
    local fn = h.post_install or h.post_checkout
    if fn then
      run_hook(fn, data)
    end
  elseif kind == "update" and h.post_checkout then
    run_hook(h.post_checkout, data)
  end
end

-- vim.pack installs every lockfile plugin on its first call, before plugin files
-- register their hooks. Remember those installs and replay hooks from M.add.
local installed_early = {} -- [plugin name] = event data

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("config_deps_hooks", { clear = true }),
  callback = function(ev)
    local p = ev.data
    local h = hooks[p.spec.name]
    if h then
      run_hooks(h, p.kind, p)
    elseif p.kind == "install" then
      installed_early[p.spec.name] = p
    end
  end,
})

---@param spec string|{source:string, name?:string, checkout?:string, hooks?:table, lazy?:boolean}|(string|table)[] a spec, or a list of specs
function M.add(spec)
  if type(spec) == "table" and spec.source == nil then
    if #spec == 0 then
      error("(deps) spec has no source", 2)
    end
    for _, item in ipairs(spec) do
      M.add(item)
    end
    return
  end
  local s = normalize(spec)
  if seen[s.name] then
    return
  end
  seen[s.name] = true
  if type(spec) == "table" and spec.hooks then
    hooks[s.name] = spec.hooks
  end
  -- vim.pack reports install progress in the cmdline; with cmdheight=0 (and ui2
  -- not enabled yet) it would be invisible, so show the cmdline during installs.
  local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. s.name
  local needs_install = vim.uv.fs_stat(pack_dir) == nil
  local cmdheight = vim.o.cmdheight
  if needs_install and cmdheight == 0 then
    vim.o.cmdheight = 1
  end
  local load = true
  if type(spec) == "table" and spec.lazy then
    load = function() end -- leave :packadd to lz.n
  end
  local ok, err = pcall(vim.pack.add, { s }, { load = load, confirm = M.config.confirm })
  if needs_install and cmdheight == 0 then
    vim.o.cmdheight = cmdheight
  end
  if not ok then
    seen[s.name] = nil
    error(err, 0)
  end
  local early = installed_early[s.name]
  if early and hooks[s.name] then
    installed_early[s.name] = nil
    early.active = true
    run_hooks(hooks[s.name], "install", early)
  end
end

function M.now(f)
  safely("now", f)
end

-- Run `f` once the event loop is free; callbacks run in order, one per tick.
function M.later(f)
  queue[#queue + 1] = f
  if draining then
    return
  end
  draining = true
  local function step()
    local next_f = table.remove(queue, 1)
    if next_f then
      safely("later", next_f)
      vim.schedule(step)
    else
      draining = false
    end
  end
  vim.schedule(step)
end

function M.update()
  vim.pack.update()
end

-- Delete plugins on disk that are not added in this session.
function M.clean()
  if draining or #queue > 0 then
    return vim.notify("(deps) Startup still loading, try again")
  end
  local names = vim
    .iter(vim.pack.get())
    :filter(function(p)
      return not p.active
    end)
    :map(function(p)
      return p.spec.name
    end)
    :totable()
  if #names == 0 then
    return vim.notify("(deps) Nothing to clean")
  end
  local msg = "Delete these plugins from disk?\n" .. table.concat(names, "\n")
  if vim.fn.confirm(msg, "&Yes\n&No", 2) == 1 then
    vim.pack.del(names)
  end
end

-- Restore all plugins to the revisions recorded in the lockfile.
function M.snap_load()
  vim.pack.update(nil, { target = "lockfile" })
end

vim.api.nvim_create_user_command("DepsUpdate", M.update, { desc = "Update plugins (vim.pack)" })
vim.api.nvim_create_user_command("DepsClean", M.clean, { desc = "Delete inactive plugins" })
vim.api.nvim_create_user_command("DepsSnapLoad", M.snap_load, { desc = "Restore plugins to lockfile" })

return M
