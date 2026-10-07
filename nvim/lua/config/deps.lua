-- Thin plugin manager on top of Neovim's built-in `vim.pack` and lz.n, in the
-- style of lazy.nvim: one spec declares what to install and when to load it.
--   setup(specs)  install every spec with vim.pack, then hand lazy-loading to lz.n
--   add(spec)     install (and load) plugins right away, without lz.n
--
-- Spec = lz.n spec fields (event, cmd, ft, keys, colorscheme, before, after,
-- priority, enabled, lazy, ...) plus:
--   [1]            "owner/repo", a full git url, or a bare name when `virtual`
--   checkout       branch, tag or commit (vim.pack `version`)
--   build          fun(data) run after install and update (data: path, source, name)
--   dependencies   string|spec[]: installed and :packadd-ed before the plugin loads
--   virtual        no package of its own, only `dependencies`
-- Specs come from `{ import = "plugins" }` (every module directly under
-- lua/plugins, returning a spec or a list of specs), like lazy.nvim, or inline.
-- A spec without triggers loads at startup; `lazy = true` waits for dependency
-- or `require("lz.n").trigger_load`. A spec with `enabled = false` is not installed.
-- Lockfile: $XDG_CONFIG_HOME/nvim/nvim-pack-lock.json (tracked in dotfiles).
-- When it exists, vim.pack installs every plugin in it at the locked revision
-- on the first vim.pack call, so require this module BEFORE any vim.pack.add.
local M = {}

M.config = { confirm = false }

local hooks = {} -- [plugin name] = { post_install = fn, post_checkout = fn }
local seen = {} -- [plugin name] = true

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
  local source = spec.source or spec[1]
  if not source:find("://", 1, true) and not source:find("^git@") then
    source = "https://github.com/" .. source
  end
  local version = spec.checkout
  if version == "HEAD" then
    version = nil
  end
  return {
    src = source,
    name = source:gsub("/+$", ""):match("([^/]+)$"):gsub("%.git$", ""),
    version = version,
  }
end

local function run_hook(fn, data)
  -- Check runtimepath, not data.active: a lazy plugin is active but not loaded.
  if not vim.list_contains(vim.opt.runtimepath:get(), data.path) then
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

local function noop() end

---A single spec has a source or is `{ "owner/repo", ... }`; anything else is a list of specs.
local function is_single(spec)
  return type(spec) == "string" or spec.source ~= nil or (type(spec[1]) == "string" and spec[2] == nil)
end

local function is_enabled(spec)
  local enabled = type(spec) == "table" and spec.enabled
  if type(enabled) == "function" then
    enabled = enabled()
  end
  return enabled ~= false
end

local function as_table(spec)
  return type(spec) == "string" and { spec } or spec
end

---Install the specs with one vim.pack.add; `lazy` ones are not loaded.
---@param items { spec: table, lazy: boolean }[]
local function install(items)
  local fresh, lazy_names, packs = {}, {}, {}
  for _, item in ipairs(items) do
    local s = normalize(item.spec)
    if not seen[s.name] then
      seen[s.name] = true
      if item.spec.build then
        hooks[s.name] = { post_install = item.spec.build, post_checkout = item.spec.build }
      end
      lazy_names[s.name] = item.lazy
      fresh[#fresh + 1] = s
      packs[#packs + 1] = s
    end
  end
  if #fresh == 0 then
    return
  end
  -- vim.pack reports install progress in the cmdline; with cmdheight=0 (and ui2
  -- not enabled yet) it would be invisible, so show the cmdline during installs.
  local pack_root = vim.fn.stdpath("data") .. "/site/pack/core/opt/"
  local needs_install = vim.iter(fresh):any(function(s)
    return vim.uv.fs_stat(pack_root .. s.name) == nil
  end)
  local cmdheight = vim.o.cmdheight
  if needs_install and cmdheight == 0 then
    vim.o.cmdheight = 1
  end
  local function load(data)
    if not lazy_names[data.spec.name] then
      vim.cmd.packadd(data.spec.name)
    end
  end
  local ok, err = pcall(vim.pack.add, packs, { load = load, confirm = M.config.confirm })
  if needs_install and cmdheight == 0 then
    vim.o.cmdheight = cmdheight
  end
  if not ok then
    for _, s in ipairs(fresh) do
      seen[s.name] = nil
    end
    error(err, 0)
  end
  for _, s in ipairs(fresh) do
    local early = installed_early[s.name]
    if early and hooks[s.name] then
      installed_early[s.name] = nil
      run_hooks(hooks[s.name], "install", early)
    end
  end
end

---Install and load plugins immediately, without lz.n.
---@param spec string|table a spec, or a list of specs
function M.add(spec)
  local items = {}
  local function collect(list)
    if type(list) == "table" and #list == 0 and list.source == nil then
      error("(deps) spec has no source", 3)
    end
    if is_single(list) then
      items[#items + 1] = { spec = as_table(list), lazy = type(list) == "table" and list.lazy == true }
    else
      for _, item in ipairs(list) do
        collect(item)
      end
    end
  end
  collect(spec)
  install(items)
end

---Modules directly under lua/<import>: files and directories with an init.lua, sorted.
---@param import string module name, e.g. "plugins"
---@return string[]
local function import_modules(import)
  local root = vim.fs.joinpath("lua", (import:gsub("%.", "/")))
  local found = {}
  for _, dir in ipairs(vim.api.nvim_get_runtime_file(root, true)) do
    for name, kind in vim.fs.dir(dir) do
      -- dotter deploys per-file symlinks, so resolve "link" entries
      local path = vim.fs.joinpath(dir, name)
      if kind == "link" then
        local stat = vim.uv.fs_stat(path)
        kind = stat and stat.type
      end
      local mod
      if kind == "file" and name:sub(-4) == ".lua" then
        mod = name:sub(1, -5)
      elseif kind == "directory" and vim.uv.fs_stat(vim.fs.joinpath(path, "init.lua")) then
        mod = name
      end
      if mod and mod ~= "init" then
        found[import .. "." .. mod] = true
      end
    end
  end
  local mods = vim.tbl_keys(found)
  table.sort(mods)
  return mods
end

-- Spec fields consumed here; everything else goes to lz.n untouched.
local own_fields = { "source", "checkout", "build", "dependencies", "virtual" }

---Install all specs, then let lz.n load them (lazily when the spec has triggers).
---@param specs table a spec, `{ import = "module" }`, or a (nested) list of them
function M.setup(specs)
  M.add("lumen-oss/lz.n")
  local items, lz_specs = {}, {}

  -- Registers dependencies for install; returns their names, dependencies of dependencies first.
  local function add_deps(list, names)
    for _, dep in ipairs(list or {}) do
      dep = as_table(dep)
      add_deps(dep.dependencies, names)
      items[#items + 1] = { spec = dep, lazy = true }
      names[#names + 1] = normalize(dep).name
    end
    return names
  end

  local function process(spec)
    if not is_enabled(spec) then
      return
    end
    local lz = {}
    for k, v in pairs(spec) do
      if not vim.list_contains(own_fields, k) then
        lz[k] = v
      end
    end
    local dep_names = add_deps(spec.dependencies, {})
    if spec.virtual then
      lz[1] = spec[1]
      lz.load = lz.load or noop
      if spec.build then
        error(("(deps) virtual spec %s cannot have build"):format(spec[1]), 3)
      end
    else
      items[#items + 1] = { spec = spec, lazy = true }
      lz[1] = normalize(spec).name
    end
    if #dep_names > 0 then
      local before = spec.before
      lz.before = function(plugin)
        for _, name in ipairs(dep_names) do
          vim.cmd.packadd(name)
        end
        if before then
          before(plugin)
        end
      end
    end
    lz_specs[#lz_specs + 1] = lz
  end

  local function walk(list)
    if list.import then
      for _, mod in ipairs(import_modules(list.import)) do
        local ok, result = pcall(require, mod)
        if ok and type(result) == "table" then
          walk(result)
        elseif not ok then
          vim.notify(("(deps) Failed to import %s: %s"):format(mod, result), vim.log.levels.ERROR)
        end
      end
    elseif is_single(list) then
      process(as_table(list))
    else
      for _, item in ipairs(list) do
        walk(item)
      end
    end
  end
  walk(specs)

  install(items)
  require("lz.n").load(lz_specs)
end

function M.update()
  vim.pack.update()
end

-- Delete plugins on disk that are not added in this session.
function M.clean()
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
