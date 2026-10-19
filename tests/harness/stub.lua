---@alias CallArgumentsProps any[]
---@alias VariadicFunctionProps fun(...: any): ...: any

---@class ReplacedEntryProps
---@field target table<string, any>
---@field key string
---@field original any

---@class stub
local stub = {}

---@type ReplacedEntryProps[]
local replaced_entries = {}

---@param target any
---@param key string
---@param value any
function stub.replace(target, key, value)
  ---@type table<string, any>
  local fields = target
  replaced_entries[#replaced_entries + 1] = {
    target = fields,
    key = key,
    original = rawget(fields, key),
  }
  rawset(fields, key, value)
end

---@param target any
---@param key string
---@return CallArgumentsProps[]
function stub.spy(target, key)
  ---@type CallArgumentsProps[]
  local calls = {}
  ---@type VariadicFunctionProps
  local original = target[key]
  stub.replace(
    target,
    key,
    ---@param ... any
    ---@return any ...
    function(...)
      calls[#calls + 1] = { ... }
      return original(...)
    end
  )
  return calls
end

function stub.restore_all()
  for index = #replaced_entries, 1, -1 do
    local entry = replaced_entries[index]
    rawset(entry.target, entry.key, entry.original)
  end
  replaced_entries = {}
end

return stub
