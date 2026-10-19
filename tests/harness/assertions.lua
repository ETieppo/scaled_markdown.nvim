local ERROR_LEVEL = 3

---@class assertions
local assertions = {}

---@param value any
---@return string
local function describe_value(value) return vim.inspect(value) end

---@param description string
---@param detail string
local function raise(description, detail)
  error(('%s\n      %s'):format(description, detail), ERROR_LEVEL)
end

---@param actual any
---@param expected any
---@param description string
function assertions.equal(actual, expected, description)
  if actual ~= expected then
    raise(
      description,
      ('expected %s, got %s'):format(
        describe_value(expected),
        describe_value(actual)
      )
    )
  end
end

---@param actual any
---@param unexpected any
---@param description string
function assertions.not_equal(actual, unexpected, description)
  if actual == unexpected then
    raise(
      description,
      ('expected anything but %s'):format(describe_value(actual))
    )
  end
end

---@param actual any
---@param expected any
---@param description string
function assertions.deep_equal(actual, expected, description)
  if not vim.deep_equal(actual, expected) then
    raise(
      description,
      ('expected %s, got %s'):format(
        describe_value(expected),
        describe_value(actual)
      )
    )
  end
end

---@param value any
---@param description string
function assertions.truthy(value, description)
  if not value then
    raise(
      description,
      ('expected truthy, got %s'):format(describe_value(value))
    )
  end
end

---@param value any
---@param description string
function assertions.falsy(value, description)
  if value then
    raise(description, ('expected falsy, got %s'):format(describe_value(value)))
  end
end

---@param value any
---@param description string
function assertions.is_nil(value, description)
  if value ~= nil then
    raise(description, ('expected nil, got %s'):format(describe_value(value)))
  end
end

---@param actual number
---@param minimum number
---@param description string
function assertions.at_least(actual, minimum, description)
  if actual == nil or actual < minimum then
    raise(
      description,
      ('expected >= %s, got %s'):format(
        tostring(minimum),
        describe_value(actual)
      )
    )
  end
end

---@param text string
---@param pattern string
---@param description string
function assertions.matches(text, pattern, description)
  if text == nil or not text:find(pattern) then
    raise(
      description,
      ('expected %s to match %s'):format(describe_value(text), pattern)
    )
  end
end

---@param list any[]
---@param item any
---@param description string
function assertions.contains(list, item, description)
  local is_found = false
  for _, candidate in ipairs(list or {}) do
    is_found = is_found or vim.deep_equal(candidate, item)
  end
  if not is_found then
    raise(
      description,
      ('expected %s to contain %s'):format(
        describe_value(list),
        describe_value(item)
      )
    )
  end
end

---@param callback fun()
---@param pattern? string
---@param description string
function assertions.fails(callback, pattern, description)
  ---@type boolean, any
  local ok, error_message = pcall(callback)
  if ok then raise(description, 'expected an error, none was raised') end
  if pattern and not tostring(error_message):find(pattern) then
    raise(
      description,
      ('expected error matching %s, got %s'):format(
        pattern,
        describe_value(error_message)
      )
    )
  end
end

---@param callback fun()
---@param description string
function assertions.succeeds(callback, description)
  ---@type boolean, any
  local ok, error_message = pcall(callback)
  if not ok then
    raise(description, ('unexpected error: %s'):format(tostring(error_message)))
  end
end

return assertions
