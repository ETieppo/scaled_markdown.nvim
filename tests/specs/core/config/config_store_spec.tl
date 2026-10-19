local type ConfigProps = require("scaled_markdown.core.types.config_props")
local type ModConfigProps = require("scaled_markdown.core.types.mod_config_props")
local RENDERER_ENUM = require("scaled_markdown.core.enums.renderer_enum")
local type RendererEnum = RENDERER_ENUM.RendererEnum
local DEFAULT_CONFIG = require("scaled_markdown.core.config.default_config")
local config_store = require("scaled_markdown.core.config.config_store")
local expect = require("harness.assertions")
local spec = require("harness.spec")

local MOD_NAME <const> = "sample"
local INVALID_RENDERER <const>: any = "nope"

local record SampleModConfigProps is ModConfigProps
    items: {string}
    size: integer
end

local function build_mod_defaults(): {string: ModConfigProps}
    local sample_defaults: SampleModConfigProps = {items = {"a", "b", "c"}, size = 1}
    return {[MOD_NAME] = sample_defaults}
end

local function build_user_config(mod_config: {string: any}): ConfigProps
    return {mods = {[MOD_NAME] = mod_config as ModConfigProps}}
end

local function invalid_config(fields: {string: any}): ConfigProps
    return fields as ConfigProps
end

local function sample_config(): SampleModConfigProps
    return config_store.get_mod_config(MOD_NAME) as SampleModConfigProps
end

spec.describe(
    "config_store",
    function()
        spec.it(
            "starts from the default config when user config is nil",
            function()
                local config = config_store.setup(nil, {})
                expect.equal(
                    config.renderer, DEFAULT_CONFIG.renderer, "default renderer"
                )
                expect.deep_equal(
                    config.file_types, DEFAULT_CONFIG.file_types, "file types"
                )
                expect.equal(config_store.get(), config, "stored config")
            end
        )

        spec.it(
            "never mutates the default config table",
            function()
                config_store.setup({reveal = {cursor_line = false}}, {})
                expect.equal(DEFAULT_CONFIG.reveal.cursor_line, true, "defaults intact")
            end
        )

        spec.it(
            "deep merges user values over defaults",
            function()
                local config = config_store.setup({reveal = {cursor_line = false}}, {})
                expect.equal(config.reveal.cursor_line, false, "user value")
                expect.equal(
                    config.reveal.visual_selection, true, "sibling default kept"
                )
            end
        )

        spec.it(
            "enables mods by default and merges mod user config",
            function()
                config_store.setup(build_user_config({size = 2}), build_mod_defaults())
                local mod_config = sample_config()
                expect.equal(mod_config.enabled, true, "enabled by default")
                expect.equal(mod_config.size, 2, "user value")
                expect.deep_equal(
                    mod_config.items, {"a", "b", "c"}, "default list kept"
                )
            end
        )

        spec.it(
            "replaces lists instead of merging them by index",
            function()
                config_store.setup(
                    build_user_config({items = {"x"}}), build_mod_defaults()
                )
                expect.deep_equal(sample_config().items, {"x"}, "replaced list")
            end
        )

        spec.it(
            "lets users disable a mod",
            function()
                config_store.setup(
                    build_user_config({enabled = false}), build_mod_defaults()
                )
                expect.equal(sample_config().enabled, false, "disabled")
            end
        )

        spec.it(
            "returns an enabled config for unknown mods",
            function()
                config_store.setup(nil, {})
                expect.deep_equal(
                    config_store.get_mod_config("unknown"),
                    {enabled = true},
                    "unknown mod"
                )
            end
        )

        spec.it(
            "rejects invalid top level values",
            function()
                expect.fails(
                    function()
                        config_store.setup(
                            invalid_config({renderer = INVALID_RENDERER}), {}
                        )
                    end,
                    "renderer",
                    "invalid renderer"
                )
                expect.fails(
                    function()
                        config_store.setup(invalid_config({enabled = "yes"}), {})
                    end,
                    "enabled",
                    "invalid enabled"
                )
                expect.fails(
                    function()
                        config_store.setup(
                            invalid_config({file_types = "markdown"}), {}
                        )
                    end,
                    "file_types",
                    "invalid file types"
                )
            end
        )

        spec.it(
            "keeps the previous config when validation fails",
            function()
                local valid_config = config_store.setup(
                    {renderer = RENDERER_ENUM.TOILET}, {}
                )
                pcall(
                    config_store.setup,
                    invalid_config({renderer = INVALID_RENDERER}),
                    {}
                )
                expect.equal(config_store.get(), valid_config, "previous config kept")
            end
        )

        spec.it(
            "validates renderer changes",
            function()
                config_store.setup(nil, {})
                config_store.set_renderer(RENDERER_ENUM.FIGLET)
                expect.equal(
                    config_store.get().renderer, RENDERER_ENUM.FIGLET, "changed"
                )
                expect.fails(
                    function()
                        config_store.set_renderer(INVALID_RENDERER as RendererEnum)
                    end,
                    "renderer",
                    "invalid renderer change"
                )
                expect.truthy(
                    config_store.is_valid_renderer(RENDERER_ENUM.PLAIN), "valid"
                )
                expect.falsy(
                    config_store.is_valid_renderer(INVALID_RENDERER), "invalid"
                )
            end
        )
    end
)
