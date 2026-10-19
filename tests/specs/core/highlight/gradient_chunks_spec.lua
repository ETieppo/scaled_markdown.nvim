local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'

local FIXED_HIGHLIGHT = 'Normal'
local GRADIENT_GROUP_PATTERN = '^ScaledMarkdownGradient%d+$'

spec.describe('gradient_chunks', function()
  spec.before_each(function() plugin_session.start() end)

  spec.it(
    'keeps the full text across chunks',
    function()
      expect.equal(
        extmark_reader.virt_line_string(
          gradient_chunks.from_text 'héllo wörld'
        ),
        'héllo wörld',
        'text preserved'
      )
    end
  )

  spec.it('colors every chunk with a gradient group', function()
    for _, chunk in ipairs(gradient_chunks.from_text 'gradient') do
      expect.matches(chunk[2], GRADIENT_GROUP_PATTERN, 'gradient group')
    end
  end)

  spec.it('merges adjacent characters that share a group', function()
    local chunks = gradient_chunks.from_text('aaaa', 1)
    expect.equal(#chunks, 1, 'single merged chunk')
    expect.equal(chunks[1][1], 'aaaa', 'merged text')
  end)

  spec.it('keeps fixed highlight segments untouched', function()
    local chunks = gradient_chunks.from_segments {
      { text = 'ab' },
      { text = '  ', highlight = FIXED_HIGHLIGHT },
    }
    expect.equal(chunks[#chunks][1], '  ', 'fixed text')
    expect.equal(chunks[#chunks][2], FIXED_HIGHLIGHT, 'fixed highlight')
  end)

  spec.it('spans the gradient from first to last column', function()
    local chunks = gradient_chunks.from_text 'abcdefghijklmnop'
    expect.equal(chunks[1][2], gradient_palette.group_at(0), 'first group')
    expect.equal(chunks[#chunks][2], gradient_palette.group_at(1), 'last group')
  end)
end)
