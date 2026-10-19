local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local RENDERER_ENUM = require("scaled_markdown.core.enums.renderer_enum")
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local extmark_reader = require("helpers.extmark_reader")
local fake_renderer = require("helpers.fake_renderer")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")
local stub = require("harness.stub")
local text_art_service = require("scaled_markdown.core.text_art.text_art_service")
local utf8_text = require("scaled_markdown.core.text.utf8_text")
local window_geometry = require("scaled_markdown.core.render.window_geometry")

local MOD_NAME <const> = "heading"
local NARROW_WINDOW_WIDTH <const> = 2
local DEEPLY_QUOTED_HEADING_COLUMN <const> = 6
local LONG_HEADING_SOURCE <const> = "###### A very long heading source"
local ART_FIRST_LINE_PATTERN <const> = "^#+"
local CURSOR_REVEAL <const> = {cursor_line = true, visual_selection = false}

local function overlay_on_row(buf: integer, row: integer): ExtmarkEntryProps
    return extmark_reader.find(
        buf,
        function(details: vim.ExtmarkOptionsProps, entry: ExtmarkEntryProps): boolean
            return entry.row == row and details.virt_text_pos == "overlay"
        end
    )
end

spec.describe(
    "heading render",
    function()
        spec.describe(
            "without text art",
            function()
                spec.before_each(
                    function() plugin_session.start_with_only(MOD_NAME) end
                )

                spec.it(
                    "overlays a single styled line on the heading row",
                    function()
                        local buf = buffer_factory.from_lines({"# Title"})
                        plugin_session.render(buf)
                        local overlay = overlay_on_row(buf, 0)
                        expect.truthy(overlay, "overlay extmark")
                        expect.matches(
                            extmark_reader.virt_text_string(overlay.details),
                            "Title",
                            "text"
                        )
                        expect.is_nil(overlay.details.virt_lines, "no extra lines")
                    end
                )

                spec.it(
                    "pads the overlay to hide the whole source line",
                    function()
                        local buf = buffer_factory.from_lines({LONG_HEADING_SOURCE})
                        plugin_session.render(buf)
                        expect.at_least(
                            utf8_text.display_width(
                                extmark_reader.virt_text_string(
                                    overlay_on_row(buf, 0).details
                                )
                            ),
                            utf8_text.display_width(LONG_HEADING_SOURCE),
                            "covers source"
                        )
                    end
                )

                spec.it(
                    "hides the setext underline line",
                    function()
                        local buf = buffer_factory.from_lines({"Title", "====="})
                        plugin_session.render(buf)
                        expect.truthy(
                            extmark_reader.find(
                                buf,
                                function(
                                    details: vim.ExtmarkOptionsProps,
                                    entry: ExtmarkEntryProps
                                ): boolean
                                    return entry.row == 1
                                        and details.conceal_lines ~= nil
                                end
                            ),
                            "underline concealed"
                        )
                    end
                )

                spec.it(
                    "renders nothing for empty headings",
                    function()
                        local buf = buffer_factory.from_lines({"#", "", "##   "})
                        plugin_session.render(buf)
                        expect.equal(#extmark_reader.list(buf), 0, "no extmarks")
                    end
                )

                spec.it(
                    "shows the source of a revealed single line heading",
                    function()
                        plugin_session.start_with_only(
                            MOD_NAME, {}, {reveal = CURSOR_REVEAL}
                        )
                        local buf = buffer_factory.from_lines({"# Title"})
                        plugin_session.render(buf)
                        expect.equal(
                            #extmark_reader.list(buf), 0, "single line heading revealed"
                        )
                    end
                )
            end
        )

        spec.describe(
            "with text art",
            function()
                spec.before_each(
                    function()
                        plugin_session.start_with_only(
                            MOD_NAME,
                            {},
                            {
                                renderer = RENDERER_ENUM.TOILET,
                            }
                        )
                        fake_renderer.install_all_unavailable()
                        fake_renderer.install(RENDERER_ENUM.TOILET, {})
                    end
                )

                spec.it(
                    "overlays the first art line and adds the rest as virtual lines",
                    function()
                        local buf = buffer_factory.from_lines({"# Title"})
                        expect.truthy(
                            plugin_session.render_until_settled(buf), "settled"
                        )
                        local overlay = overlay_on_row(buf, 0)
                        expect.truthy(overlay, "overlay")
                        expect.matches(
                            extmark_reader.virt_text_string(overlay.details),
                            ART_FIRST_LINE_PATTERN,
                            "art first line"
                        )
                        expect.equal(
                            #overlay.details.virt_lines,
                            fake_renderer.ART_HEIGHT - 1,
                            "remaining art lines"
                        )
                    end
                )

                spec.it(
                    "keeps blank virtual lines when the art heading is revealed",
                    function()
                        plugin_session.start_with_only(
                            MOD_NAME,
                            {},
                            {
                                renderer = RENDERER_ENUM.TOILET,
                                reveal = CURSOR_REVEAL,
                            }
                        )
                        local buf = buffer_factory.from_lines({"# Title"})
                        plugin_session.render_until_settled(buf)
                        local placeholder = extmark_reader.on_row(buf, 0)[1]
                        expect.truthy(placeholder, "placeholder")
                        expect.is_nil(placeholder.details.virt_text, "source visible")
                        expect.equal(
                            #placeholder.details.virt_lines,
                            fake_renderer.ART_HEIGHT - 1,
                            "height kept"
                        )
                    end
                )

                spec.it(
                    "requests art at least one column wide in narrow windows",
                    function()
                        local calls = stub.spy(text_art_service, "request")
                        local buf = buffer_factory.from_lines({">   > # Deeply quoted"})
                        vim.cmd.vsplit()
                        vim.api.nvim_win_set_width(0, NARROW_WINDOW_WIDTH)
                        expect.truthy(
                            window_geometry.text_area_width(
                                0
                            ) < DEEPLY_QUOTED_HEADING_COLUMN,
                            "window narrower than the heading column"
                        )
                        plugin_session.render(buf)
                        expect.at_least(#calls, 1, "requested")
                        for _, call in ipairs(calls) do
                            expect.at_least(call[3] as integer, 1, "positive width")
                        end
                    end
                )
            end
        )
    end
)
