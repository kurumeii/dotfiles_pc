--- Context-keyed cache, modelled on blink.cmp's sources/lsp/cache.lua.
--- One entry per id (e.g. an LSP client id); an entry is only valid for the context
--- (`key`) it was stored under.

--- @class CacheEntry
--- @field key string Context the value was stored under
--- @field pos number Position within the context (e.g. cursor column)
--- @field value any

--- @class Cache
--- @field entries table<any, CacheEntry>
local Cache = {}
Cache.__index = Cache

--- @return Cache
function Cache.new()
  return setmetatable({ entries = {} }, Cache)
end

--- Valid for the same context as long as the position has not moved backward.
--- @param id any
--- @param key string
--- @param pos number
--- @return any? value
function Cache:get(id, key, pos)
  local entry = self.entries[id]
  if entry and entry.key == key and entry.pos <= pos then
    return entry.value
  end
end

--- @param id any
--- @param key string
--- @param pos number
--- @param value any
function Cache:set(id, key, pos, value)
  self.entries[id] = { key = key, pos = pos, value = value }
end

function Cache:clear()
  self.entries = {}
end

return Cache
