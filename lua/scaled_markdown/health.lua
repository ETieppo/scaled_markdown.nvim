local health_report = require 'scaled_markdown.core.health.health_report'

---@class HealthProps
---@field check fun()

---@type HealthProps
local HEALTH = {
  check = health_report.run,
}

return HEALTH
