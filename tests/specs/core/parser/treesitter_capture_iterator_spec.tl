local type CaptureProps = require("scaled_markdown.core.types.capture_props")
local type RegisteredModProps = require(
    "scaled_markdown.core.types.registered_mod_props"
)
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local spec = require("harness.spec")
local stub = require("harness.stub")
local treesitter_capture_iterator = require(
    "scaled_markdown.core.parser.treesitter_capture_iterator"
)

local REPEATED_BLOCKS <const> = 200
local INLINE_LINE <const> = "some *emphasis* here"
local VIEWPORT_START_ROW <const> = 0
local VIEWPORT_END_ROW <const> = 10
local ROWS_PER_BLOCK <const> = 2
local EMPHASIS_QUERY <const> = "(emphasis) @emphasis"
local EMPHASIS_TEXT <const> = "*emphasis*"

local function build_inline_blocks(): {string}
    local lines: {string} = {}
    for _ = 1, REPEATED_BLOCKS do
        lines[#lines + 1] = INLINE_LINE
        lines[#lines + 1] = ""
    end
    return lines
end

local function build_registered_mod(): RegisteredModProps
    return {
        props = {name = "emphasis", language = "markdown_inline"},
        query = vim.treesitter.query.parse("markdown_inline", EMPHASIS_QUERY),
    }
end

spec.describe(
    "treesitter_capture_iterator",
    function()
        spec.it(
            "returns nil when the buffer has no markdown parser",
            function()
                vim.cmd.enew()
                local buf = vim.api.nvim_get_current_buf()
                stub.replace(
                    vim.treesitter, "get_parser", function(): any return nil end
                )
                expect.is_nil(
                    treesitter_capture_iterator.collect_trees_by_language(buf, 0, 1),
                    "no trees"
                )
            end
        )

        spec.it(
            "collects the markdown tree and inline trees by language",
            function()
                local buf = buffer_factory.from_lines({"# Title", "", INLINE_LINE})
                local trees = treesitter_capture_iterator.collect_trees_by_language(
                    buf, 0, 3
                )
                expect.equal(#trees.markdown, 1, "markdown tree")
                expect.at_least(#(trees.markdown_inline or {}), 1, "inline trees")
            end
        )

        spec.it(
            "keeps only the inline trees that cross the viewport",
            function()
                local buf = buffer_factory.from_lines(build_inline_blocks())
                vim.treesitter.get_parser(buf, "markdown"):parse(true)
                local trees = treesitter_capture_iterator.collect_trees_by_language(
                    buf, VIEWPORT_START_ROW, VIEWPORT_END_ROW
                )
                local inline_trees = trees.markdown_inline or {}
                expect.at_least(#inline_trees, 1, "viewport trees kept")
                expect.truthy(#inline_trees < REPEATED_BLOCKS, "distant trees dropped")
                for _, tree in ipairs(inline_trees) do
                    local tree_start_row, _, tree_end_row = tree:root():range()
                    expect.truthy(
                        tree_start_row < VIEWPORT_END_ROW
                            and tree_end_row >= VIEWPORT_START_ROW,
                        "tree crosses viewport"
                    )
                end
            end
        )

        spec.it(
            "yields captures inside the requested rows only",
            function()
                local buf = buffer_factory.from_lines(build_inline_blocks())
                local trees = treesitter_capture_iterator.collect_trees_by_language(
                    buf, VIEWPORT_START_ROW, VIEWPORT_END_ROW
                )
                local captures: {CaptureProps} = {}
                treesitter_capture_iterator.for_each_capture(
                    trees,
                    build_registered_mod(),
                    buf,
                    VIEWPORT_START_ROW,
                    VIEWPORT_END_ROW,
                    function(capture_dto: CaptureProps)
                        captures[#captures + 1] = capture_dto
                    end
                )
                expect.equal(
                    #captures,
                    math.floor(VIEWPORT_END_ROW / ROWS_PER_BLOCK),
                    "one emphasis per block"
                )
                for _, capture_dto in ipairs(captures) do
                    expect.equal(capture_dto.name, "emphasis", "capture name")
                    expect.equal(capture_dto.text, EMPHASIS_TEXT, "capture text")
                    expect.truthy(
                        capture_dto.start_row < VIEWPORT_END_ROW, "inside rows"
                    )
                end
            end
        )
    end
)
