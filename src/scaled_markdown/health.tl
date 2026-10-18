local health_report = require 'scaled_markdown.core.health.health_report'

local record HealthProps
  check: function()
end

local HEALTH: HealthProps = {
  check = health_report.run,
}

return HEALTH
