local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local MOD_NAME = 'checkbox'
---@type string[]
local LINES = { '- [ ] pending', '- [x] done' }
local UNCHECKED_GROUP = 'ScaledMarkdownCheckboxUnchecked'
local CHECKED_GROUP = 'ScaledMarkdownCheckboxChecked'
local CUSTOM_UNCHECKED_ICON = 'o'
local CUSTOM_CHECKED_ICON = 'x'

---@param mod_config? CheckboxConfigProps
---@return integer
local function render(mod_config)
  plugin_session.start_with_only(MOD_NAME, mod_config)
  local buf = buffer_factory.from_lines(LINES)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@param row integer
---@return ExtmarkEntryProps
local function marker_on_row(buf, row)
  return extmark_reader.find(
    buf,
    ---@param details vim.api.keyset.set_extmark
    ---@param entry ExtmarkEntryProps
    ---@return boolean
    function(details, entry) return entry.row == row and details.conceal ~= nil end
  )
end

spec.describe('checkbox render', function()
  spec.it('replaces unchecked and checked markers with their icons', function()
    local buf = render()
    local mod_config = plugin_session.mod_config(MOD_NAME) --[[@as CheckboxConfigProps]]
    local unchecked = marker_on_row(buf, 0)
    local checked = marker_on_row(buf, 1)
    expect.equal(
      unchecked.details.conceal,
      mod_config.unchecked_icon,
      'unchecked'
    )
    expect.equal(unchecked.details.hl_group, UNCHECKED_GROUP, 'unchecked group')
    expect.equal(checked.details.conceal, mod_config.checked_icon, 'checked')
    expect.equal(checked.details.hl_group, CHECKED_GROUP, 'checked group')
  end)

  spec.it('covers exactly the bracket marker', function()
    local unchecked = marker_on_row(render(), 0)
    expect.equal(
      LINES[1]:sub(unchecked.col + 1, unchecked.details.end_col),
      '[ ]',
      'marker range'
    )
  end)

  spec.it('uses the configured icons', function()
    local buf = render {
      unchecked_icon = CUSTOM_UNCHECKED_ICON,
      checked_icon = CUSTOM_CHECKED_ICON,
    }
    expect.equal(
      marker_on_row(buf, 0).details.conceal,
      CUSTOM_UNCHECKED_ICON,
      'u'
    )
    expect.equal(
      marker_on_row(buf, 1).details.conceal,
      CUSTOM_CHECKED_ICON,
      'c'
    )
  end)
end)
