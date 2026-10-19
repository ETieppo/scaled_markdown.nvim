local type CodeBlockProps = require("scaled_markdown.mods.code_block.code_block_props")
local CODE_BLOCK_QUERY = require("scaled_markdown.mods.code_block.query")
local capture_builder = require("helpers.capture_builder")
local code_block_dto_builder = require(
    "scaled_markdown.mods.code_block.code_block_dto_builder"
)
local expect = require("harness.assertions")
local spec = require("harness.spec")

local function build_code_block_dto(lines: {string}): CodeBlockProps
    local captures, buf = capture_builder.from_lines(lines, CODE_BLOCK_QUERY)
    return code_block_dto_builder.build(captures[1], buf)
end

spec.describe(
    "code_block_dto_builder",
    function()
        spec.it(
            "reads fences, language and content rows of fenced blocks",
            function()
                expect.deep_equal(
                    build_code_block_dto(
                        {
                            "intro",
                            "",
                            "```lua",
                            "local a = 1",
                            "print(a)",
                            "```",
                        }
                    ),
                    {
                        language = "lua",
                        left_col = 0,
                        opening_fence_row = 2,
                        closing_fence_row = 5,
                        first_content_row = 3,
                        last_content_row = 4,
                    },
                    "fenced block"
                )
            end
        )

        spec.it(
            "takes the language word from a longer info string",
            function()
                expect.equal(
                    build_code_block_dto(
                        {'```python title="x"', "pass", "```"}
                    ).language,
                    "python",
                    "language"
                )
            end
        )

        spec.it(
            "has no language for bare fences",
            function()
                expect.is_nil(
                    build_code_block_dto({"```", "x", "```"}).language, "no language"
                )
            end
        )

        spec.it(
            "reads indented blocks without fences",
            function()
                local code_block_dto = build_code_block_dto(
                    {"para", "", "    code one", "    code two"}
                )
                expect.is_nil(code_block_dto.opening_fence_row, "no opening fence")
                expect.is_nil(code_block_dto.closing_fence_row, "no closing fence")
                expect.equal(code_block_dto.first_content_row, 2, "first row")
                expect.equal(code_block_dto.last_content_row, 3, "last row")
            end
        )

        spec.it(
            "ignores trailing blank rows of unclosed blocks",
            function()
                local code_block_dto = build_code_block_dto({"```", "code", "", ""})
                expect.is_nil(code_block_dto.closing_fence_row, "unclosed")
                expect.equal(code_block_dto.last_content_row, 1, "last non blank row")
            end
        )

        spec.it(
            "handles empty fenced blocks",
            function()
                local code_block_dto = build_code_block_dto({"```", "```"})
                expect.equal(
                    code_block_dto.first_content_row, 1, "first row after fence"
                )
                expect.equal(code_block_dto.last_content_row, 0, "empty content range")
            end
        )
    end
)
