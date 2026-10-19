local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local text_line_layout = require 'scaled_markdown.core.layout.text_line_layout'
local text_word_wrapper =
  require 'scaled_markdown.core.layout.text_word_wrapper'

local ADVANCE_WIDTH = 10
local KERNED_PAIR_ADJUSTMENT = -3
local LETTER_A = 0x41
local LETTER_V = 0x56

---@return FontFaceProps
local function build_monospace_face()
  return {
    units_per_em = 100,
    ascender = 80,
    descender = -20,
    line_gap = 0,
    find_glyph_index = function(codepoint) return codepoint end,
    advance_width = function(_) return ADVANCE_WIDTH end,
    kerning = function(left, right)
      return (left == LETTER_A and right == LETTER_V) and KERNED_PAIR_ADJUSTMENT
        or 0
    end,
    load_outline = function(_) return { commands = {} } end,
  }
end

spec.describe('text layout', function()
  spec.it('places glyphs by advance width and kerning', function()
    local layout = text_line_layout.layout(build_monospace_face(), 'AVA')
    expect.deep_equal(
      vim.tbl_map(
        ---@param placement GlyphPlacementProps
        ---@return number
        function(placement) return placement.x end,
        layout.placements
      ),
      { 0, 7, 17 },
      'pen positions'
    )
    expect.equal(layout.advance_width, 27, 'advance')
  end)

  spec.it(
    'wraps words greedily by measured width',
    function()
      expect.deep_equal(
        text_word_wrapper.wrap(build_monospace_face(), 'one two three', 70),
        { 'one two', 'three' },
        'lines'
      )
    end
  )

  spec.it(
    'breaks words wider than the line',
    function()
      expect.deep_equal(
        text_word_wrapper.wrap(build_monospace_face(), 'abcdefgh', 30),
        { 'abc', 'def', 'gh' },
        'pieces'
      )
    end
  )

  spec.it('collapses whitespace and drops blank text', function()
    expect.deep_equal(
      text_word_wrapper.wrap(build_monospace_face(), '  a   b  ', 100),
      { 'a b' },
      'collapsed'
    )
    expect.deep_equal(
      text_word_wrapper.wrap(build_monospace_face(), '   ', 100),
      {},
      'blank'
    )
  end)
end)
