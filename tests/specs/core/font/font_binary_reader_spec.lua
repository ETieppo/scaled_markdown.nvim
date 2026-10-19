local expect = require 'harness.assertions'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'
local spec = require 'harness.spec'

local SAMPLE_BYTES = '\255\254\0\1\64\0\1\2\3\4'

spec.describe('font_binary_reader', function()
  spec.it('reads unsigned and signed big endian integers', function()
    expect.equal(font_binary_reader.read_uint8(SAMPLE_BYTES, 0), 255, 'uint8')
    expect.equal(font_binary_reader.read_int8(SAMPLE_BYTES, 0), -1, 'int8')
    expect.equal(
      font_binary_reader.read_uint16(SAMPLE_BYTES, 0),
      65534,
      'uint16'
    )
    expect.equal(font_binary_reader.read_int16(SAMPLE_BYTES, 0), -2, 'int16')
    expect.equal(
      font_binary_reader.read_uint32(SAMPLE_BYTES, 6),
      16909060,
      'uint32'
    )
    expect.equal(
      font_binary_reader.read_int32(SAMPLE_BYTES, 0),
      -131071,
      'int32'
    )
    expect.equal(
      font_binary_reader.read_uint_of_size(SAMPLE_BYTES, 6, 3),
      66051,
      'uint24'
    )
  end)

  spec.it('reads fixed point numbers', function()
    expect.equal(font_binary_reader.read_f2dot14(SAMPLE_BYTES, 4), 1, 'f2dot14')
    expect.equal(font_binary_reader.read_fixed(SAMPLE_BYTES, 2), 1.25, 'fixed')
  end)

  spec.it(
    'reads zero past the end of the data',
    function()
      expect.equal(
        font_binary_reader.read_uint16(SAMPLE_BYTES, 100),
        0,
        'missing bytes'
      )
    end
  )

  spec.it('tests single bit flags', function()
    expect.truthy(font_binary_reader.has_flag(5, 4), 'set flag')
    expect.falsy(font_binary_reader.has_flag(5, 2), 'unset flag')
  end)
end)
