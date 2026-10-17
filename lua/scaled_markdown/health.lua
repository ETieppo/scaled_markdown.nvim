local health_report = require 'scaled_markdown.core.health.health_report'

return {
  check = health_report.run,
}
