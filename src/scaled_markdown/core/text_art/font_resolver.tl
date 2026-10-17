local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local process_runner = require 'scaled_markdown.core.text_art.process_runner'

local FONT_MATCH_EXECUTABLE <const> = 'fc-match'
local FONT_MATCH_FORMAT <const> = '%{file}|%{style}'
local FONT_MATCH_SEPARATOR_PATTERN <const> = '^(.-)|(.*)$'
local REQUESTED_STYLE_PATTERN <const> = ':(%a+)$'
local UNRESOLVED_FONT_MARKER <const> = false

local record font_resolver
end

local resolved_file_by_query: {string: string | boolean} = {}

local function warn_style_mismatch(font_query: string, resolved_style: string)
  vim.notify(
    ("[%s] font '%s' resolved to style '%s'"):format(
      CORE_CONSTANTS.PLUGIN_NAME,
      font_query,
      resolved_style
    ),
    vim.log.levels.WARN
  )
end

local function match_font(font_query: string): string
  if vim.uv.fs_stat(font_query) then return font_query end
  if vim.fn.executable(FONT_MATCH_EXECUTABLE) == 0 then return nil end
  local result = process_runner.run_sync(
    { FONT_MATCH_EXECUTABLE, '-f', FONT_MATCH_FORMAT, font_query },
    { text = true },
    CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS
  )
  local font_file, resolved_style = (result.stdout or ''):match(
    FONT_MATCH_SEPARATOR_PATTERN
  )
  if result.code ~= 0 or not font_file or font_file == '' then return nil end
  local requested_style = font_query:match(REQUESTED_STYLE_PATTERN)
  if
    requested_style
    and not resolved_style:lower():find(requested_style:lower(), 1, true)
  then
    warn_style_mismatch(font_query, resolved_style)
  end
  return font_file
end

function font_resolver.resolve(font_query: string): string
  if resolved_file_by_query[font_query] == nil then
    resolved_file_by_query[font_query] = match_font(font_query)
      or UNRESOLVED_FONT_MARKER
  end
  local resolved_file = resolved_file_by_query[font_query]
  return resolved_file is string and resolved_file or nil
end

function font_resolver.is_available(): boolean
  return vim.fn.executable(FONT_MATCH_EXECUTABLE) == 1
end

return font_resolver
