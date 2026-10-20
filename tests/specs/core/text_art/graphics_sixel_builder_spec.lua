local expect = require 'harness.assertions'
local graphics_sixel_builder =
  require 'scaled_markdown.core.text_art.graphics_sixel_builder'
local spec = require 'harness.spec'

---@type string[]
local GRADIENT = { '#000000', '#ffffff' }
local BACKGROUND = '#000000'

---@param sixel string
---@return string[]
local function color_definitions(sixel)
  ---@type string[]
  local definitions = {}
  for definition in sixel:gmatch '#%d+;2;%d+;%d+;%d+' do
    definitions[#definitions + 1] = definition
  end
  return definitions
end

spec.describe('graphics_sixel_builder', function()
  spec.it('maps gradient ends and coverage to blended colors', function()
    local sixel = graphics_sixel_builder.build(
      { width = 2, height = 1, values = { 1, 1 } },
      2,
      2,
      1,
      GRADIENT,
      BACKGROUND
    )
    expect.deep_equal(
      color_definitions(sixel),
      { '#7;2;0;0;0', '#255;2;100;100;100' },
      'dark start and bright end'
    )
  end)

  spec.it('blends partial coverage with the background', function()
    local sixel = graphics_sixel_builder.build(
      { width = 1, height = 1, values = { 0.5 } },
      1,
      1,
      1,
      { '#ffffff' },
      '#000000'
    )
    expect.deep_equal(color_definitions(sixel), { '#3;2;50;50;50' }, 'half')
  end)

  spec.it('leaves empty pixels and padding transparent', function()
    local sixel = graphics_sixel_builder.build(
      { width = 1, height = 1, values = { 0 } },
      1,
      2,
      2,
      GRADIENT,
      BACKGROUND
    )
    expect.deep_equal(color_definitions(sixel), {}, 'no colors')
    expect.matches(sixel, '"1;1;2;2', 'padded raster size')
  end)
end)
