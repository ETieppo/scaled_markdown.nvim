local type ConfigProps = require("scaled_markdown.core.types.config_props")
local type ModConfigProps = require("scaled_markdown.core.types.mod_config_props")
local config_store = require("scaled_markdown.core.config.config_store")
local mod_registry = require("scaled_markdown.core.registry.mod_registry")
local render_pipeline = require("scaled_markdown.core.render.render_pipeline")
local scaled_markdown = require("scaled_markdown")
local text_art_service = require("scaled_markdown.core.text_art.text_art_service")

local TEXT_ART_WAIT_MS <const> = 10000
local MAX_SETTLE_ROUNDS <const> = 6
local PLAIN_CONFIG <const>: ConfigProps = {renderer = "plain"}
local NO_REVEAL <const>: ConfigProps.RevealProps = {
    cursor_line = false, visual_selection = false
}

local record plugin_session
end

function plugin_session.start(config?: ConfigProps)
    scaled_markdown.setup(config or vim.deepcopy(PLAIN_CONFIG))
end

function plugin_session.mod_names(): {string}
    local names: {string} = {}
    for _, registered_mod in ipairs(mod_registry.list()) do
        names[#names + 1] = registered_mod.props.name
    end
    return names
end

function plugin_session.start_with_only(
    mod_name: string, mod_config?: {string: any}, base_config?: ConfigProps
)
    plugin_session.start()
    local mods_config: {string: ModConfigProps} = {}
    for _, name in ipairs(plugin_session.mod_names()) do
        mods_config[name] = {enabled = name == mod_name}
    end
    mods_config[mod_name] = vim.tbl_extend(
        "force", {enabled = true} as {string: any}, mod_config or {}
    ) as ModConfigProps
    local session_config: ConfigProps = vim.tbl_extend(
        "force",
        {renderer = "plain", reveal = NO_REVEAL, mods = mods_config} as ConfigProps,
        base_config or {}
    )
    plugin_session.start(session_config)
end

function plugin_session.render(buf: integer)
    render_pipeline.render(buf)
end

function plugin_session.wait_for_text_art(): boolean
    return vim.wait(
        TEXT_ART_WAIT_MS,
        function(): boolean return not text_art_service.has_pending() end
    )
end

function plugin_session.render_until_settled(buf: integer): boolean
    for _ = 1, MAX_SETTLE_ROUNDS do
        plugin_session.render(buf)
        if not text_art_service.has_pending() then
            return true
        end
        plugin_session.wait_for_text_art()
    end
    return false
end

function plugin_session.mod_config(mod_name: string): ModConfigProps
    return config_store.get_mod_config(mod_name)
end

return plugin_session
