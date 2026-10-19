local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local buffer_state_store =
  require 'scaled_markdown.core.buffer.buffer_state_store'

local FIRST_BUFFER = 1001
local SECOND_BUFFER = 1002

spec.describe('buffer_state_store', function()
  spec.after_each(function()
    buffer_state_store.mark_detached(FIRST_BUFFER)
    buffer_state_store.mark_detached(SECOND_BUFFER)
  end)

  spec.it('tracks attached buffers', function()
    buffer_state_store.mark_attached(FIRST_BUFFER)
    expect.truthy(buffer_state_store.is_attached(FIRST_BUFFER), 'attached')
    expect.falsy(buffer_state_store.is_attached(SECOND_BUFFER), 'other buffer')
  end)

  spec.it('forgets detached buffers', function()
    buffer_state_store.mark_attached(FIRST_BUFFER)
    buffer_state_store.mark_detached(FIRST_BUFFER)
    expect.falsy(buffer_state_store.is_attached(FIRST_BUFFER), 'detached')
  end)

  spec.it('lists every attached buffer once', function()
    buffer_state_store.mark_attached(FIRST_BUFFER)
    buffer_state_store.mark_attached(SECOND_BUFFER)
    buffer_state_store.mark_attached(SECOND_BUFFER)
    local attached = buffer_state_store.list_attached()
    table.sort(attached)
    expect.deep_equal(attached, { FIRST_BUFFER, SECOND_BUFFER }, 'listed')
  end)
end)
