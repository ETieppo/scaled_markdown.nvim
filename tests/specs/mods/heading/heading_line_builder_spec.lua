local HEADING_LINE_STYLE_ENUM =
  require 'scaled_markdown.mods.heading.heading_line_style_enum'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local heading_line_builder =
  require 'scaled_markdown.mods.heading.heading_line_builder'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local MUTED_GROUP = 'ScaledMarkdownHeadingMuted'
local FILL_GROUP_PATTERN = '^ScaledMarkdownGradientFill%d+$'
local FOREGROUND_GROUP_PATTERN = '^ScaledMarkdownGradient%d+$'
local HEADING_TEXT = 'Title'
local LABEL_FORMAT = '%s %s'
local PILL_LEVEL = 1
local ACCENT_LEVEL = 5
local MUTED_LEVEL = 6
---@type any
local UNKNOWN_LINE_STYLE = 'unknown'

---@param level integer
---@return HeadingProps
local function build_heading(level)
  return { level = level, text = HEADING_TEXT, row = 0, start_col = 0 }
end

---@param mod_config HeadingConfigProps
---@param level integer
---@return string
local function build_label(mod_config, level)
  return LABEL_FORMAT:format(mod_config.icons_by_level[level], HEADING_TEXT)
end

spec.describe('heading_line_builder', function()
  ---@type HeadingConfigProps
  local mod_config

  spec.before_each(function()
    plugin_session.start()
    mod_config = plugin_session.mod_config 'heading' --[[@as HeadingConfigProps]]
  end)

  spec.it('renders pill levels with caps and a filled body', function()
    local chunks =
      heading_line_builder.build(build_heading(PILL_LEVEL), mod_config)
    local text = extmark_reader.virt_line_string(chunks)
    expect.truthy(vim.startswith(text, mod_config.pill_caps.left), 'left cap')
    expect.truthy(vim.endswith(text, mod_config.pill_caps.right), 'right cap')
    expect.truthy(
      text:find(build_label(mod_config, PILL_LEVEL), 1, true),
      'icon and text'
    )
    local has_fill = false
    for _, chunk in ipairs(chunks) do
      has_fill = has_fill or chunk[2]:match(FILL_GROUP_PATTERN) ~= nil
    end
    expect.truthy(has_fill, 'filled body')
  end)

  spec.it('renders accent levels with a foreground gradient', function()
    local chunks =
      heading_line_builder.build(build_heading(ACCENT_LEVEL), mod_config)
    for _, chunk in ipairs(chunks) do
      expect.matches(chunk[2], FOREGROUND_GROUP_PATTERN, 'foreground gradient')
    end
    expect.equal(
      extmark_reader.virt_line_string(chunks),
      build_label(mod_config, ACCENT_LEVEL),
      'icon and text'
    )
  end)

  spec.it(
    'renders muted levels with the muted group',
    function()
      expect.deep_equal(
        heading_line_builder.build(build_heading(MUTED_LEVEL), mod_config),
        { { build_label(mod_config, MUTED_LEVEL), MUTED_GROUP } },
        'muted'
      )
    end
  )

  spec.it('falls back to muted for unknown line styles', function()
    mod_config.line_styles_by_level[PILL_LEVEL] = UNKNOWN_LINE_STYLE
    local chunks =
      heading_line_builder.build(build_heading(PILL_LEVEL), mod_config)
    expect.equal(chunks[1][2], MUTED_GROUP, 'muted fallback')
  end)

  spec.it('omits the icon when the level has none', function()
    mod_config.icons_by_level = {}
    local chunks =
      heading_line_builder.build(build_heading(MUTED_LEVEL), mod_config)
    expect.equal(chunks[1][1], HEADING_TEXT, 'text only')
  end)
end)
