local type TextArtStyleProps = require(
    "scaled_markdown.core.types.text_art_style_props"
)

local record FakeRendererProps
    record OptionsProps
        available: boolean
        fails: boolean
    end

    record CallProps
        text: string
        style: TextArtStyleProps
        width: integer
    end
end

return FakeRendererProps
