local TMUX_EXECUTABLE = 'tmux'
local FIELD_SEPARATOR = '\t'
local FEATURE_SEPARATOR = ','
local TRAILING_NEWLINE_PATTERN = '\n$'
local COMMAND_TIMEOUT_MS = 1000
local PASSTHROUGH_OPTION = 'allow-passthrough'
local PASSTHROUGH_ALL = 'all'
local PASSTHROUGH_ON = 'on'
---@type string[]
local PASSTHROUGH_VALUES_BY_PREFERENCE = { PASSTHROUGH_ALL, PASSTHROUGH_ON }
local INHERITED_OPTION_VALUE = ''
---@type string[]
local PROBE_FIELDS = {
  '#{client_termname}',
  '#{client_termtype}',
  '#{client_termfeatures}',
  '#{client_cell_width}',
  '#{client_cell_height}',
  '#{' .. PASSTHROUGH_OPTION .. '}',
}
local UNPROBED = nil
local PROBE_FAILED = false

---@class tmux_client
local tmux_client = {}

---@type TmuxClientProps|boolean|nil
local cached_probe = UNPROBED
local has_tried_passthrough = false
---@type string?
local original_passthrough = nil

---@param subcommand string
---@param arguments string[]
---@return string?
local function run(subcommand, arguments)
  if vim.fn.executable(TMUX_EXECUTABLE) ~= 1 then return nil end
  local command = { TMUX_EXECUTABLE, subcommand }
  if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= '' then
    vim.list_extend(command, { '-t', vim.env.TMUX_PANE })
  end
  vim.list_extend(command, arguments)
  local ok, process = pcall(vim.system, command, { text = true })
  if not ok then return nil end
  local result = process:wait(COMMAND_TIMEOUT_MS)
  if result.code ~= 0 then return nil end
  return result.stdout or ''
end

---@param text string?
---@return integer?
local function parse_positive_integer(text)
  local value = tonumber(text)
  if not value or value <= 0 then return nil end
  return math.floor(value)
end

---@param text string
---@return table<string, boolean>
local function parse_features(text)
  ---@type table<string, boolean>
  local features = {}
  for _, feature in
    ipairs(
      vim.split(text, FEATURE_SEPARATOR, { plain = true, trimempty = true })
    )
  do
    features[feature] = true
  end
  return features
end

---@param output string
---@return TmuxClientProps?
local function parse_probe(output)
  local fields = vim.split(
    output:gsub(TRAILING_NEWLINE_PATTERN, ''),
    FIELD_SEPARATOR,
    { plain = true }
  )
  if #fields < #PROBE_FIELDS then return nil end
  return {
    term_name = fields[1],
    term_type = fields[2],
    features = parse_features(fields[3]),
    cell_width = parse_positive_integer(fields[4]),
    cell_height = parse_positive_integer(fields[5]),
    passthrough = fields[6],
  }
end

---@return boolean
function tmux_client.is_inside()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ''
end

---@return TmuxClientProps?
function tmux_client.probe()
  if not tmux_client.is_inside() then return nil end
  if cached_probe == UNPROBED then
    local output = run(
      'display-message',
      { '-p', table.concat(PROBE_FIELDS, FIELD_SEPARATOR) }
    )
    cached_probe = output and parse_probe(output) or PROBE_FAILED
  end
  if cached_probe == PROBE_FAILED then return nil end
  return cached_probe --[[@as TmuxClientProps]]
end

local function remember_original_passthrough()
  if original_passthrough ~= nil then return end
  local output = run('show-options', { '-p', '-q', '-v', PASSTHROUGH_OPTION })
  original_passthrough = output and vim.trim(output) or INHERITED_OPTION_VALUE
end

---@param client_props TmuxClientProps
local function raise_passthrough(client_props)
  remember_original_passthrough()
  for _, value in ipairs(PASSTHROUGH_VALUES_BY_PREFERENCE) do
    if run('set-option', { '-p', PASSTHROUGH_OPTION, value }) then
      client_props.passthrough = value
      return
    end
  end
end

---@param may_change_option boolean
---@return boolean
function tmux_client.ensure_passthrough(may_change_option)
  local client_props = tmux_client.probe()
  if not client_props then return false end
  if client_props.passthrough == PASSTHROUGH_ALL then return true end
  if may_change_option and not has_tried_passthrough then
    has_tried_passthrough = true
    raise_passthrough(client_props)
  end
  return client_props.passthrough == PASSTHROUGH_ALL
    or client_props.passthrough == PASSTHROUGH_ON
end

function tmux_client.restore_passthrough()
  if original_passthrough == nil then return end
  if original_passthrough == INHERITED_OPTION_VALUE then
    run('set-option', { '-p', '-u', PASSTHROUGH_OPTION })
  else
    run('set-option', { '-p', PASSTHROUGH_OPTION, original_passthrough })
  end
  original_passthrough = nil
end

function tmux_client.reset()
  cached_probe = UNPROBED
  has_tried_passthrough = false
end

return tmux_client
