---@class CapturedMessageProps
---@field message string
---@field level integer

---@class notify_capture
local notify_capture = {}

---@type CapturedMessageProps[]
local captured_messages = {}

---@param message string
---@param level? integer
local function capture_notification(message, level)
  captured_messages[#captured_messages + 1] = {
    message = tostring(message),
    level = level or vim.log.levels.INFO,
  }
end

function notify_capture.install() rawset(vim, 'notify', capture_notification) end

---@param level? integer
---@return string[]
function notify_capture.take(level)
  ---@type string[]
  local taken = {}
  ---@type CapturedMessageProps[]
  local kept = {}
  for _, entry in ipairs(captured_messages) do
    if level == nil or entry.level == level then
      taken[#taken + 1] = entry.message
    else
      kept[#kept + 1] = entry
    end
  end
  captured_messages = kept
  return taken
end

---@return string[]
function notify_capture.take_errors()
  return notify_capture.take(vim.log.levels.ERROR)
end

function notify_capture.reset() captured_messages = {} end

return notify_capture
