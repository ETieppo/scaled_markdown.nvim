local buffer_factory = require 'helpers.buffer_factory'
local conceal_reader = require 'helpers.conceal_reader'
local expect = require 'harness.assertions'
local extmark_predicates = require 'helpers.extmark_predicates'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local MOD_NAME = 'link'
local TEXT_GROUP = 'ScaledMarkdownLinkText'
local ICON_GROUP = 'ScaledMarkdownLinkIcon'
local LINK_COLUMN = 4
local CUSTOM_ICON = '>> '

---@param lines string[]
---@param mod_config? LinkConfigProps
---@return integer
local function render(lines, mod_config)
  plugin_session.start_with_only(MOD_NAME, mod_config)
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@return LinkConfigProps
local function link_config()
  return plugin_session.mod_config(MOD_NAME) --[[@as LinkConfigProps]]
end

spec.describe('link render', function()
  spec.it('shows only the label of inline links behind an icon', function()
    local buf = render { 'see [Neovim](https://neovim.io) now' }
    expect.equal(conceal_reader.visible_text(buf, 0), 'see Neovim now', 'label')
    local icon = extmark_reader.find(buf, extmark_predicates.is_inline)
    expect.deep_equal(
      icon.details.virt_text,
      { { link_config().icon, ICON_GROUP } },
      'icon'
    )
    expect.equal(icon.col, LINK_COLUMN, 'icon before link')
    expect.truthy(
      extmark_reader.find(buf, extmark_predicates.with_highlight(TEXT_GROUP)),
      'label highlighted'
    )
  end)

  spec.it('renders full reference links like inline links', function()
    local buf = render { 'a [Label][ref] b', '', '[ref]: https://x.y' }
    expect.equal(conceal_reader.visible_text(buf, 0), 'a Label b', 'label only')
  end)

  spec.it('strips the angle brackets of autolinks', function()
    local buf = render { 'go <https://example.com> now' }
    expect.equal(
      conceal_reader.visible_text(buf, 0),
      'go https://example.com now',
      'url only'
    )
    expect.deep_equal(
      extmark_reader.find(buf, extmark_predicates.is_inline).details.virt_text,
      { { link_config().autolink_icon, ICON_GROUP } },
      'autolink icon'
    )
  end)

  spec.it('uses the configured icons', function()
    local buf = render({ '[a](b)' }, { icon = CUSTOM_ICON })
    expect.equal(
      extmark_reader.find(buf, extmark_predicates.is_inline).details.virt_text[1][1],
      CUSTOM_ICON,
      'custom icon'
    )
  end)
end)
