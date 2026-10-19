local expect = require 'harness.assertions'
local kitty_graphics_protocol =
  require 'scaled_markdown.core.terminal.kitty_graphics_protocol'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

local IMAGE_ID = 7
local CHUNK_SIZE = 4096
local CONTROL_SEPARATOR = ';'
local SMALL_PIXELS = string.rep('\1\2\3\4', 4)
local LARGE_PIXELS = string.rep('\255\128\0\255', 3000)

---@param control_payload string
---@return string, string
local function split_payload(control_payload)
  local separator_index = control_payload:find(CONTROL_SEPARATOR, 1, true)
  return control_payload:sub(1, separator_index - 1),
    control_payload:sub(separator_index + 1)
end

---@param is_inside boolean
---@return string[]
local function capture_sent(is_inside)
  stub.replace(tmux_client, 'is_inside', function() return is_inside end)
  ---@type string[]
  local sent = {}
  stub.replace(
    vim.api,
    'nvim_ui_send',
    ---@param data string
    function(data) sent[#sent + 1] = data end
  )
  return sent
end

spec.describe('kitty_graphics_protocol', function()
  spec.it('sends a small image in a single final chunk', function()
    local payloads = kitty_graphics_protocol.build_transmit_payloads(
      IMAGE_ID,
      SMALL_PIXELS,
      2,
      2,
      1,
      1
    )
    expect.equal(#payloads, 1, 'one chunk')
    local control, data = split_payload(payloads[1])
    expect.equal(
      control,
      'a=T,U=1,f=32,s=2,v=2,t=d,q=2,i=7,c=1,r=1,m=0',
      'control keys'
    )
    expect.equal(vim.base64.decode(data), SMALL_PIXELS, 'pixels')
  end)

  spec.it('splits large images into chunks of the protocol size', function()
    local payloads = kitty_graphics_protocol.build_transmit_payloads(
      IMAGE_ID,
      LARGE_PIXELS,
      100,
      30,
      10,
      2
    )
    expect.at_least(#payloads, 3, 'several chunks')
    ---@type string[]
    local encoded_chunks = {}
    for index, payload in ipairs(payloads) do
      local control, data = split_payload(payload)
      local is_last = index == #payloads
      if index == 1 then
        expect.matches(control, '^a=T,U=1,.*,m=1$', 'first chunk keys')
      else
        expect.equal(
          control,
          is_last and 'q=2,m=0' or 'q=2,m=1',
          'next chunk keys'
        )
      end
      expect.truthy(#data <= CHUNK_SIZE, 'chunk size')
      if not is_last then
        expect.equal(#data % 4, 0, 'chunk aligned to base64 quads')
      end
      encoded_chunks[index] = data
    end
    expect.equal(
      vim.base64.decode(table.concat(encoded_chunks)),
      LARGE_PIXELS,
      'pixels'
    )
  end)

  spec.it('writes plain escapes outside tmux', function()
    local sent = capture_sent(false)
    kitty_graphics_protocol.delete_image(IMAGE_ID)
    expect.deep_equal(sent, { '\27_Ga=d,d=I,q=2,i=7\27\\' }, 'plain escape')
  end)

  spec.it('wraps every chunk in tmux passthrough inside tmux', function()
    local sent = capture_sent(true)
    kitty_graphics_protocol.transmit_pixels(
      IMAGE_ID,
      LARGE_PIXELS,
      100,
      30,
      10,
      2
    )
    expect.equal(#sent, 1, 'single write')
    local chunk_count = #kitty_graphics_protocol.build_transmit_payloads(
      IMAGE_ID,
      LARGE_PIXELS,
      100,
      30,
      10,
      2
    )
    local _, wrapper_count = sent[1]:gsub('\27Ptmux;', '')
    expect.equal(wrapper_count, chunk_count, 'one wrapper per chunk')
    expect.falsy(sent[1]:find '[^\27]\27_G', 'every escape doubled')
  end)
end)
