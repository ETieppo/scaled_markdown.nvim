local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local font_face_loader = require 'scaled_markdown.core.font.font_face_loader'
local font_resolver = require 'scaled_markdown.core.text_art.font_resolver'
local spec = require 'harness.spec'

local COMPACT_FONT_QUERY = 'FreeSans:bold'
local TRUE_TYPE_FONT_QUERY = 'Liberation Sans'
local LETTER_A_CODEPOINT = 0x41
local A_ACUTE_CODEPOINT = 0xE1
local UNMAPPED_CODEPOINT = 0x10FFFD

---@param font_query string
---@return FontFaceProps?
local function load_face_for(font_query)
  spec.skip_unless(
    environment.has_font(font_query),
    environment.missing_font_reason(font_query)
  )
  return font_face_loader.load(assert(font_resolver.resolve(font_query)))
end

---@param font_query string
local function assert_face_draws(font_query)
  local face = load_face_for(font_query)
  expect.truthy(face, 'face loaded')
  ---@cast face -nil
  expect.at_least(face.units_per_em, 16, 'units per em')
  expect.truthy(face.ascender > 0 and face.descender < 0, 'vertical metrics')
  local glyph_index = face.find_glyph_index(LETTER_A_CODEPOINT)
  expect.at_least(glyph_index, 1, 'mapped glyph')
  expect.at_least(face.advance_width(glyph_index), 1, 'advance width')
  expect.at_least(
    #face.load_outline(glyph_index).commands,
    3,
    'outline commands'
  )
  local accented_index = face.find_glyph_index(A_ACUTE_CODEPOINT)
  expect.at_least(
    #face.load_outline(accented_index).commands,
    #face.load_outline(glyph_index).commands + 1,
    'accent drawn with base letter'
  )
  expect.equal(face.find_glyph_index(UNMAPPED_CODEPOINT), 0, 'missing glyph')
end

spec.describe('font_face_loader', function()
  spec.it(
    'loads compact font format outlines',
    function() assert_face_draws(COMPACT_FONT_QUERY) end
  )

  spec.it(
    'loads true type outlines with composite glyphs',
    function() assert_face_draws(TRUE_TYPE_FONT_QUERY) end
  )

  spec.it(
    'returns nil for files that are not fonts',
    function()
      expect.is_nil(
        font_face_loader.load { path = vim.v.progpath, face_index = 0 },
        'not a font'
      )
    end
  )
end)
