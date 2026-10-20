local expect = require 'harness.assertions'
local sixel_encoder = require 'scaled_markdown.core.terminal.sixel_encoder'
local spec = require 'harness.spec'

local SEQUENCE_START = '\27P0;1;0q'
local SEQUENCE_END = '\27\\'
---@type integer[][]
local RED_AND_BLUE = { { 255, 0, 0 }, { 0, 0, 255 } }

spec.describe('sixel_encoder', function()
  spec.it(
    'writes raster size, used colors and transparent pixels',
    function()
      expect.equal(
        sixel_encoder.encode({ 1, 0 }, 2, 1, RED_AND_BLUE),
        SEQUENCE_START .. '"1;1;2;1#0;2;100;0;0#0@$-' .. SEQUENCE_END,
        'single pixel'
      )
    end
  )

  spec.it(
    'stacks six rows per band and starts a new band after',
    function()
      expect.equal(
        sixel_encoder.encode({ 2, 2, 2, 2, 2, 2, 2 }, 1, 7, RED_AND_BLUE),
        SEQUENCE_START .. '"1;1;1;7#1;2;0;0;100#1~$-#1@$-' .. SEQUENCE_END,
        'two bands'
      )
    end
  )

  spec.it(
    'compresses long runs and keeps colors on separate passes',
    function()
      expect.equal(
        sixel_encoder.encode({ 1, 1, 1, 1, 1, 2 }, 6, 1, RED_AND_BLUE),
        SEQUENCE_START
          .. '"1;1;6;1#0;2;100;0;0#1;2;0;0;100#0!5@$#1!5?@$-'
          .. SEQUENCE_END,
        'runs'
      )
    end
  )
end)
