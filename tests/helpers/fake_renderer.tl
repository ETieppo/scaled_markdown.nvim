local type FakeRendererProps = require("helpers.types.fake_renderer_props")
local type TextArtProps = require("scaled_markdown.core.types.text_art_props")
local type TextArtStyleProps = require(
    "scaled_markdown.core.types.text_art_style_props"
)
local RENDERER_ENUM = require("scaled_markdown.core.enums.renderer_enum")
local type RendererEnum = RENDERER_ENUM.RendererEnum
local stub = require("harness.stub")

local ART_HEIGHT <const> = 2
local COLUMNS_PER_CHARACTER <const> = 2
local ART_CHARACTER <const> = "#"
local RENDERER_MODULE_FORMAT <const> = "scaled_markdown.core.text_art.%s_renderer"
local TEXT_ART_RENDERERS <const>: {RendererEnum} = {
    RENDERER_ENUM.GRAPHICS,
    RENDERER_ENUM.TYPEFACE,
    RENDERER_ENUM.TOILET,
    RENDERER_ENUM.FIGLET,
}

local type OptionsProps = FakeRendererProps.OptionsProps
local type CallProps = FakeRendererProps.CallProps

local record fake_renderer
    ART_HEIGHT: integer
    COLUMNS_PER_CHARACTER: integer
end

local function build_art(text: string): TextArtProps
    local line = string.rep(ART_CHARACTER, #text * COLUMNS_PER_CHARACTER)
    local lines: {string} = {}
    for index = 1, ART_HEIGHT do
        lines[index] = line
    end
    return {lines = lines}
end

function fake_renderer.install(
    renderer: RendererEnum, options: OptionsProps
): {CallProps}
    local renderer_module = require(RENDERER_MODULE_FORMAT:format(renderer))
    local calls: {CallProps} = {}
    stub.replace(
        renderer_module,
        "is_available",
        function(): boolean return options.available ~= false end
    )
    stub.replace(
        renderer_module,
        "render_async",
        function(
            text: string,
            style_props: TextArtStyleProps,
            width: integer,
            on_done: function(TextArtProps)
        )
            calls[#calls + 1] = {text = text, style = style_props, width = width}
            vim.schedule(
                function()
                    if options.fails then
                        on_done(nil)
                    else
                        on_done(build_art(text))
                    end
                end
            )
        end
    )
    return calls
end

function fake_renderer.install_all_unavailable()
    for _, renderer in ipairs(TEXT_ART_RENDERERS) do
        fake_renderer.install(renderer, {available = false})
    end
end

fake_renderer.ART_HEIGHT = ART_HEIGHT
fake_renderer.COLUMNS_PER_CHARACTER = COLUMNS_PER_CHARACTER

return fake_renderer
