local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local subcommand_handlers =
  require 'scaled_markdown.core.command.subcommand_handlers'

local user_command = {}

local function list_subcommand_names()
  local names = vim.tbl_keys(subcommand_handlers)
  table.sort(names)
  return names
end

local function filter_by_prefix(candidates, prefix)
  return vim.tbl_filter(
    function(candidate) return vim.startswith(candidate, prefix) end,
    candidates
  )
end

local function execute(command_options)
  local subcommand_name = command_options.fargs[1]
  local handler = subcommand_handlers[subcommand_name]

  if not handler then
    vim.notify(
      ('[%s] unknown subcommand: %s'):format(
        CORE_CONSTANTS.PLUGIN_NAME,
        tostring(subcommand_name)
      ),
      vim.log.levels.ERROR
    )
    return
  end

  local ok, error_message =
    pcall(handler.run, vim.list_slice(command_options.fargs, 2))
  if not ok then
    vim.notify(
      ('[%s] %s'):format(CORE_CONSTANTS.PLUGIN_NAME, error_message),
      vim.log.levels.ERROR
    )
  end
end

local function complete(argument_lead, command_line)
  local arguments = vim.split(command_line, '%s+', { trimempty = true })
  local is_typing_new_argument = command_line:match '%s$' ~= nil
  local argument_position = #arguments - (is_typing_new_argument and 0 or 1)

  if argument_position <= 1 then
    return filter_by_prefix(list_subcommand_names(), argument_lead)
  end

  local handler = subcommand_handlers[arguments[2]]
  if handler and handler.complete then
    return filter_by_prefix(handler.complete(), argument_lead)
  end

  return {}
end

function user_command.register()
  vim.api.nvim_create_user_command(CORE_CONSTANTS.COMMAND_NAME, execute, {
    nargs = '+',
    complete = complete,
    desc = 'Control scaled markdown rendering',
  })
end

return user_command
