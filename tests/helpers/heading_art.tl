local type HeadingConfigProps = require("scaled_markdown.mods.heading.config_props")
local type TextArtProps = require("scaled_markdown.core.types.text_art_props")
local heading_style_resolver = require(
    "scaled_markdown.mods.heading.heading_style_resolver"
)
local plugin_session = require("helpers.plugin_session")
local text_art_service = require("scaled_markdown.core.text_art.text_art_service")

local MAX_REQUEST_ROUNDS <const> = 6
local HEADING_MOD_NAME <const> = "heading"

local record heading_art
end

function heading_art.request(text: string, level: integer, width: integer): TextArtProps
    local heading_config = plugin_session.mod_config(HEADING_MOD_NAME)
        as HeadingConfigProps
    local style_by_renderer = heading_style_resolver.resolve(
        heading_config.styles, level
    )
    for _ = 1, MAX_REQUEST_ROUNDS do
        local text_art_dto = text_art_service.request(text, style_by_renderer, width)
        if text_art_dto then
            return text_art_dto
        end
        if not text_art_service.has_pending() then
            return nil
        end
        plugin_session.wait_for_text_art()
    end
    return nil
end

return heading_art
