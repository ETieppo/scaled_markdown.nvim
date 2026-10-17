local enum LanguageEnum
  'markdown'
  'markdown_inline'
end

local record LanguageEnumProps
  type LanguageEnum = LanguageEnum

  MARKDOWN: LanguageEnum
  MARKDOWN_INLINE: LanguageEnum
end

local LANGUAGE_ENUM <const>: LanguageEnumProps = {
  MARKDOWN = 'markdown',
  MARKDOWN_INLINE = 'markdown_inline',
}

return LANGUAGE_ENUM
