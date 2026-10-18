local health_report = require('scaled_markdown.core.health.health_report')





local HEALTH = {
   check = health_report.run,
}

return HEALTH
