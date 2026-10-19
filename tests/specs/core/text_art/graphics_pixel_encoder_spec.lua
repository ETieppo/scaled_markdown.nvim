local expect = require 'harness.assertions'
local graphics_pixel_encoder =
  require 'scaled_markdown.core.text_art.graphics_pixel_encoder'
local spec = require 'harness.spec'

local BYTES_PER_PIXEL = 4
local OPAQUE_ALPHA = 255
---@type string[]
local METALLIC_COLORS = { '#202020', '#ffffff', '#202020' }

---@param width integer
---@return CoverageBitmapProps
local function build_full_coverage_row(width)
  ---@type number[]
  local values = {}
  for column = 1, width do
    values[column] = 1
  end
  return { width = width, height = 1, values = values }
end

---@param pixels string
---@param column integer
---@return integer[]
local function pixel_at(pixels, column)
  local offset = (column - 1) * BYTES_PER_PIXEL
  return { pixels:byte(offset + 1, offset + BYTES_PER_PIXEL) }
end

spec.describe('graphics_pixel_encoder', function()
  spec.it('colors columns through every gradient stop', function()
    local pixels = graphics_pixel_encoder.encode_rgba(
      build_full_coverage_row(3),
      3,
      3,
      1,
      METALLIC_COLORS
    )
    expect.deep_equal(
      pixel_at(pixels, 1),
      { 32, 32, 32, OPAQUE_ALPHA },
      'start'
    )
    expect.deep_equal(
      pixel_at(pixels, 2),
      { 255, 255, 255, OPAQUE_ALPHA },
      'middle highlight'
    )
    expect.deep_equal(pixel_at(pixels, 3), { 32, 32, 32, OPAQUE_ALPHA }, 'end')
  end)

  spec.it('leaves uncovered and padding pixels transparent', function()
    local pixels = graphics_pixel_encoder.encode_rgba(
      { width = 2, height = 1, values = { 0, 1 } },
      2,
      3,
      2,
      METALLIC_COLORS
    )
    expect.equal(#pixels, 3 * 2 * BYTES_PER_PIXEL, 'image size')
    expect.deep_equal(pixel_at(pixels, 1), { 0, 0, 0, 0 }, 'uncovered')
    expect.deep_equal(pixel_at(pixels, 3), { 0, 0, 0, 0 }, 'beyond ink')
    expect.deep_equal(pixel_at(pixels, 4), { 0, 0, 0, 0 }, 'padding row')
  end)
end)
