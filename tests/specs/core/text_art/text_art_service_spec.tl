local type FakeRendererProps = require("helpers.types.fake_renderer_props")
local type TextArtProps = require("scaled_markdown.core.types.text_art_props")
local type TextArtStyleProps = require(
    "scaled_markdown.core.types.text_art_style_props"
)
local RENDERER_ENUM = require("scaled_markdown.core.enums.renderer_enum")
local type RendererEnum = RENDERER_ENUM.RendererEnum
local config_store = require("scaled_markdown.core.config.config_store")
local expect = require("harness.assertions")
local fake_renderer = require("helpers.fake_renderer")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")
local text_art_service = require("scaled_markdown.core.text_art.text_art_service")

local TEXT <const> = "Heading"
local WRAPPED_TEXT <const> = "one two three"
local FIRST_SEGMENT <const> = "one two"
local SECOND_SEGMENT <const> = "three"
local WIDE_WIDTH <const> = 200
local REPEATED_REQUESTS <const> = 5
local MAX_REQUEST_ROUNDS <const> = 6

local type CallProps = FakeRendererProps.CallProps
local type StyleByRendererProps = {RendererEnum: TextArtStyleProps}

local function build_styles(): StyleByRendererProps
    return {
        [RENDERER_ENUM.GRAPHICS] = {font = "Sans", line_height_cells = 2},
        [RENDERER_ENUM.TYPEFACE] = {font = "Sans", symbols = "block", rows = 2},
        [RENDERER_ENUM.TOILET] = {font = "mono9"},
        [RENDERER_ENUM.FIGLET] = {font = "standard"},
    }
end

local function request_settled(text: string, width: integer): TextArtProps
    local art: TextArtProps
    for _ = 1, MAX_REQUEST_ROUNDS do
        art = text_art_service.request(text, build_styles(), width)
        if not text_art_service.has_pending() then
            return art
        end
        plugin_session.wait_for_text_art()
    end
    return art
end

local function rendered_texts(calls: {CallProps}): {string}
    return vim.tbl_map(function(call: CallProps): string return call.text end, calls)
end

spec.describe(
    "text_art_service",
    function()
        spec.before_each(
            function()
                plugin_session.start()
                fake_renderer.install_all_unavailable()
            end
        )

        spec.after_each(
            function()
                expect.truthy(plugin_session.wait_for_text_art(), "renders drained")
            end
        )

        spec.it(
            "returns nothing and renders nothing for the plain renderer",
            function()
                local calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                expect.is_nil(
                    text_art_service.request(TEXT, build_styles(), WIDE_WIDTH), "nil"
                )
                expect.equal(#calls, 0, "no render started")
                expect.falsy(text_art_service.has_pending(), "nothing pending")
            end
        )

        spec.it(
            "is pending first and serves the cached art afterwards",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                local calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                expect.is_nil(
                    text_art_service.request(TEXT, build_styles(), WIDE_WIDTH),
                    "pending"
                )
                expect.truthy(text_art_service.has_pending(), "has pending")
                plugin_session.wait_for_text_art()
                local art = text_art_service.request(TEXT, build_styles(), WIDE_WIDTH)
                expect.equal(#art.lines, fake_renderer.ART_HEIGHT, "art lines")
                expect.equal(#calls, 1, "rendered once")
            end
        )

        spec.it(
            "never re-renders cached art for freshly built styles",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                local calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                request_settled(TEXT, WIDE_WIDTH)
                for _ = 1, REPEATED_REQUESTS do
                    text_art_service.request(TEXT, build_styles(), WIDE_WIDTH)
                end
                expect.equal(#calls, 1, "single render for repeated requests")
                expect.falsy(text_art_service.has_pending(), "nothing pending")
            end
        )

        spec.it(
            "does not start a duplicate render while one is pending",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                local calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                text_art_service.request(TEXT, build_styles(), WIDE_WIDTH)
                text_art_service.request(TEXT, build_styles(), WIDE_WIDTH)
                plugin_session.wait_for_text_art()
                expect.equal(#calls, 1, "deduplicated")
            end
        )

        spec.it(
            "falls back to the next renderer when the preferred one fails",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                fake_renderer.install(RENDERER_ENUM.TOILET, {fails = true})
                local figlet_calls = fake_renderer.install(RENDERER_ENUM.FIGLET, {})
                expect.truthy(request_settled(TEXT, WIDE_WIDTH), "fallback art")
                expect.equal(#figlet_calls, 1, "figlet used")
            end
        )

        spec.it(
            "skips renderers that are unavailable",
            function()
                config_store.set_renderer(RENDERER_ENUM.GRAPHICS)
                local graphics_calls = fake_renderer.install(
                    RENDERER_ENUM.GRAPHICS, {available = false}
                )
                local toilet_calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                expect.truthy(request_settled(TEXT, WIDE_WIDTH), "art")
                expect.equal(#graphics_calls, 0, "graphics skipped")
                expect.equal(#toilet_calls, 1, "toilet used")
            end
        )

        spec.it(
            "skips renderers without a style",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                local toilet_calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                local styles = build_styles()
                styles[RENDERER_ENUM.TOILET] = nil
                expect.is_nil(
                    text_art_service.request(TEXT, styles, WIDE_WIDTH), "no art"
                )
                expect.equal(#toilet_calls, 0, "toilet skipped")
            end
        )

        spec.it(
            "returns nil when every renderer fails",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                fake_renderer.install(RENDERER_ENUM.TOILET, {fails = true})
                fake_renderer.install(RENDERER_ENUM.FIGLET, {fails = true})
                expect.is_nil(request_settled(TEXT, WIDE_WIDTH), "no art")
            end
        )

        spec.it(
            "notifies the ready listener when art arrives",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                fake_renderer.install(RENDERER_ENUM.TOILET, {})
                local ready_count = 0
                text_art_service.set_ready_listener(
                    function() ready_count = ready_count + 1 end
                )
                request_settled(TEXT, WIDE_WIDTH)
                expect.equal(ready_count, 1, "listener called once")
            end
        )

        spec.it(
            "renders again after the cache is cleared",
            function()
                config_store.set_renderer(RENDERER_ENUM.TOILET)
                local calls = fake_renderer.install(RENDERER_ENUM.TOILET, {})
                request_settled(TEXT, WIDE_WIDTH)
                text_art_service.clear_cache()
                request_settled(TEXT, WIDE_WIDTH)
                expect.equal(#calls, 2, "rendered twice")
            end
        )

        spec.it(
            "wraps words for renderers that cannot wrap natively",
            function()
                config_store.set_renderer(RENDERER_ENUM.TYPEFACE)
                local calls = fake_renderer.install(RENDERER_ENUM.TYPEFACE, {})
                local narrow_width = #FIRST_SEGMENT * fake_renderer.COLUMNS_PER_CHARACTER
                local art = request_settled(WRAPPED_TEXT, narrow_width)
                expect.truthy(art, "wrapped art")
                expect.equal(
                    #art.lines, fake_renderer.ART_HEIGHT * 2, "two stacked segments"
                )
                expect.contains(
                    rendered_texts(calls), FIRST_SEGMENT, "first segment rendered"
                )
                expect.contains(
                    rendered_texts(calls), SECOND_SEGMENT, "second segment rendered"
                )
            end
        )
    end
)
