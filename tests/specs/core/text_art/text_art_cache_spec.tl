local type TextArtStyleProps = require(
    "scaled_markdown.core.types.text_art_style_props"
)
local expect = require("harness.assertions")
local spec = require("harness.spec")
local text_art_cache = require("scaled_markdown.core.text_art.text_art_cache")

local RENDERER <const> = "typeface"
local OTHER_RENDERER <const> = "toilet"
local WIDTH <const> = 80
local TEXT <const> = "Heading"
local OTHER_TEXT <const> = "Other"
local TABLE_ADDRESS_MARKER <const> = "table: "

local function build_style(): TextArtStyleProps
    return {font = "FreeSans:bold", symbols = "block", rows = 3}
end

local function build_list_style(): TextArtStyleProps
    local list_style: {string: any} = {font = {"a", "b"}}
    return list_style as TextArtStyleProps
end

spec.describe(
    "text_art_cache",
    function()
        spec.before_each(function() text_art_cache.clear() end)

        spec.describe(
            "build_key",
            function()
                spec.it(
                    "is stable for equal styles built separately",
                    function()
                        expect.equal(
                            text_art_cache.build_key(
                                RENDERER, build_style(), WIDTH, TEXT
                            ),
                            text_art_cache.build_key(
                                RENDERER, build_style(), WIDTH, TEXT
                            ),
                            "same key"
                        )
                    end
                )

                spec.it(
                    "serializes list values by content, not table identity",
                    function()
                        local first_key = text_art_cache.build_key(
                            RENDERER, build_list_style(), WIDTH, TEXT
                        )
                        local second_key = text_art_cache.build_key(
                            RENDERER, build_list_style(), WIDTH, TEXT
                        )
                        expect.equal(first_key, second_key, "list styles share a key")
                        expect.falsy(
                            first_key:find(TABLE_ADDRESS_MARKER, 1, true), "no address"
                        )
                    end
                )

                spec.it(
                    "distinguishes renderer, style, width and text",
                    function()
                        local base_key = text_art_cache.build_key(
                            RENDERER, build_style(), WIDTH, TEXT
                        )
                        local other_style = build_style()
                        other_style.rows = 4
                        local keys_by_change: {string: string} = {
                            renderer = text_art_cache.build_key(
                                OTHER_RENDERER, build_style(), WIDTH, TEXT
                            ),
                            style = text_art_cache.build_key(
                                RENDERER, other_style, WIDTH, TEXT
                            ),
                            width = text_art_cache.build_key(
                                RENDERER, build_style(), WIDTH + 1, TEXT
                            ),
                            text = text_art_cache.build_key(
                                RENDERER, build_style(), WIDTH, OTHER_TEXT
                            ),
                        }
                        for change, key in pairs(keys_by_change) do
                            expect.not_equal(
                                key, base_key, change .. " changes the key"
                            )
                        end
                    end
                )

                spec.it(
                    "does not depend on style field insertion order",
                    function()
                        expect.equal(
                            text_art_cache.build_key(
                                RENDERER, {font = "a", rows = 1}, WIDTH, TEXT
                            ),
                            text_art_cache.build_key(
                                RENDERER, {rows = 1, font = "a"}, WIDTH, TEXT
                            ),
                            "order independent"
                        )
                    end
                )
            end
        )

        spec.describe(
            "lookup and store",
            function()
                spec.it(
                    "returns nil for unknown keys",
                    function()
                        expect.is_nil(text_art_cache.lookup("missing"), "unknown key")
                    end
                )

                spec.it(
                    "returns the stored art",
                    function()
                        text_art_cache.store("key", {lines = {"x"}})
                        expect.deep_equal(
                            text_art_cache.lookup("key"), {lines = {"x"}}, "stored"
                        )
                    end
                )

                spec.it(
                    "remembers failed renders as false",
                    function()
                        text_art_cache.store("key", nil)
                        expect.equal(
                            text_art_cache.lookup("key"), false, "failure marker"
                        )
                    end
                )

                spec.it(
                    "forgets everything on clear",
                    function()
                        text_art_cache.store("key", {lines = {"x"}})
                        text_art_cache.clear()
                        expect.is_nil(text_art_cache.lookup("key"), "cleared")
                    end
                )
            end
        )
    end
)
