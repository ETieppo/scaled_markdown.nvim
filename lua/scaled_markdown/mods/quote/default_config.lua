local CALLOUT_TYPE_ENUM = require 'scaled_markdown.mods.quote.callout_type_enum'

---@type QuoteConfigProps
local DEFAULT_QUOTE_CONFIG = {
  bar = '▌',
  callouts = {
    [CALLOUT_TYPE_ENUM.NOTE] = {
      icon = '󰋽 ',
      title = 'Note',
      color = 'DiagnosticInfo',
    },
    [CALLOUT_TYPE_ENUM.TIP] = {
      icon = '󰌶 ',
      title = 'Tip',
      color = 'DiagnosticOk',
    },
    [CALLOUT_TYPE_ENUM.IMPORTANT] = {
      icon = '󰅾 ',
      title = 'Important',
      color = 'DiagnosticHint',
    },
    [CALLOUT_TYPE_ENUM.WARNING] = {
      icon = '󰀪 ',
      title = 'Warning',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.WARN] = {
      icon = '󰀪 ',
      title = 'Warning',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.CAUTION] = {
      icon = '󰳦 ',
      title = 'Caution',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.ABSTRACT] = {
      icon = '󰨸 ',
      title = 'Abstract',
      color = 'DiagnosticHint',
    },
    [CALLOUT_TYPE_ENUM.SUMMARY] = {
      icon = '󰨸 ',
      title = 'Summary',
      color = 'DiagnosticHint',
    },
    [CALLOUT_TYPE_ENUM.TLDR] = {
      icon = '󰨸 ',
      title = 'Tldr',
      color = 'DiagnosticHint',
    },
    [CALLOUT_TYPE_ENUM.INFO] = {
      icon = '󰋽 ',
      title = 'Info',
      color = 'DiagnosticInfo',
    },
    [CALLOUT_TYPE_ENUM.TODO] = {
      icon = '󰗡 ',
      title = 'Todo',
      color = 'DiagnosticInfo',
    },
    [CALLOUT_TYPE_ENUM.HINT] = {
      icon = '󰌶 ',
      title = 'Hint',
      color = 'DiagnosticOk',
    },
    [CALLOUT_TYPE_ENUM.SUCCESS] = {
      icon = '󰄬 ',
      title = 'Success',
      color = 'DiagnosticOk',
    },
    [CALLOUT_TYPE_ENUM.CHECK] = {
      icon = '󰄬 ',
      title = 'Check',
      color = 'DiagnosticOk',
    },
    [CALLOUT_TYPE_ENUM.DONE] = {
      icon = '󰄬 ',
      title = 'Done',
      color = 'DiagnosticOk',
    },
    [CALLOUT_TYPE_ENUM.QUESTION] = {
      icon = '󰘥 ',
      title = 'Question',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.HELP] = {
      icon = '󰘥 ',
      title = 'Help',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.FAQ] = {
      icon = '󰘥 ',
      title = 'Faq',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.ATTENTION] = {
      icon = '󰀪 ',
      title = 'Attention',
      color = 'DiagnosticWarn',
    },
    [CALLOUT_TYPE_ENUM.FAILURE] = {
      icon = ' ',
      title = 'Failure',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.FAIL] = {
      icon = ' ',
      title = 'Fail',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.MISSING] = {
      icon = '󰲉 ',
      title = 'Missing',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.DANGER] = {
      icon = '☢ ',
      title = 'Danger',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.ERROR] = {
      icon = ' ',
      title = 'Error',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.BUG] = {
      icon = '󰨰 ',
      title = 'Bug',
      color = 'DiagnosticError',
    },
    [CALLOUT_TYPE_ENUM.EXAMPLE] = {
      icon = '󱐌 ',
      title = 'Example',
      color = 'Special',
    },
    [CALLOUT_TYPE_ENUM.QUOTE] = {
      icon = '󱆨 ',
      title = 'Quote',
      color = 'Comment',
    },
    [CALLOUT_TYPE_ENUM.CITE] = {
      icon = '󱆨 ',
      title = 'Cite',
      color = 'Comment',
    },
  },
}

return DEFAULT_QUOTE_CONFIG
