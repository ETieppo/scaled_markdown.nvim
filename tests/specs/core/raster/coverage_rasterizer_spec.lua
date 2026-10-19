local coverage_rasterizer =
  require 'scaled_markdown.core.raster.coverage_rasterizer'
local expect = require 'harness.assertions'
local spec = require 'harness.spec'

local CANVAS_SIZE = 4
local TOLERANCE = 1e-9

---@param left number
---@param top number
---@param right number
---@param bottom number
---@return CoverageBitmapProps
local function draw_square(left, top, right, bottom)
  local canvas = coverage_rasterizer.create_canvas(CANVAS_SIZE, CANVAS_SIZE)
  coverage_rasterizer.draw_line(canvas, left, top, right, top)
  coverage_rasterizer.draw_line(canvas, right, top, right, bottom)
  coverage_rasterizer.draw_line(canvas, right, bottom, left, bottom)
  coverage_rasterizer.draw_line(canvas, left, bottom, left, top)
  return coverage_rasterizer.to_bitmap(canvas)
end

---@param bitmap CoverageBitmapProps
---@param column integer
---@param row integer
---@return number
local function coverage_at(bitmap, column, row)
  return bitmap.values[row * bitmap.width + column + 1]
end

---@param actual number
---@param expected number
---@param description string
local function expect_close(actual, expected, description)
  expect.truthy(
    math.abs(actual - expected) < TOLERANCE,
    ('%s: expected %g, got %g'):format(description, expected, actual)
  )
end

spec.describe('coverage_rasterizer', function()
  spec.it('fully covers pixels inside a pixel aligned square', function()
    local bitmap = draw_square(1, 1, 3, 3)
    for row = 0, CANVAS_SIZE - 1 do
      for column = 0, CANVAS_SIZE - 1 do
        local is_inside = row >= 1 and row <= 2 and column >= 1 and column <= 2
        expect_close(
          coverage_at(bitmap, column, row),
          is_inside and 1 or 0,
          ('pixel %d,%d'):format(column, row)
        )
      end
    end
  end)

  spec.it('computes partial coverage for edges inside pixels', function()
    local bitmap = draw_square(0.5, 0.5, 1.5, 1.5)
    expect_close(coverage_at(bitmap, 0, 0), 0.25, 'top left')
    expect_close(coverage_at(bitmap, 1, 0), 0.25, 'top right')
    expect_close(coverage_at(bitmap, 0, 1), 0.25, 'bottom left')
    expect_close(coverage_at(bitmap, 1, 1), 0.25, 'bottom right')
    expect_close(coverage_at(bitmap, 2, 2), 0, 'outside')
  end)

  spec.it('covers half of the pixels crossed by a diagonal edge', function()
    local canvas = coverage_rasterizer.create_canvas(CANVAS_SIZE, CANVAS_SIZE)
    coverage_rasterizer.draw_line(canvas, 0, 0, 4, 4)
    coverage_rasterizer.draw_line(canvas, 4, 4, 0, 4)
    coverage_rasterizer.draw_line(canvas, 0, 4, 0, 0)
    local bitmap = coverage_rasterizer.to_bitmap(canvas)
    expect_close(coverage_at(bitmap, 1, 1), 0.5, 'diagonal pixel')
    expect_close(coverage_at(bitmap, 0, 3), 1, 'inside pixel')
    expect_close(coverage_at(bitmap, 3, 0), 0, 'outside pixel')
  end)
end)
