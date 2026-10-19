local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record CheckboxHighlightGroupsProps
  UNCHECKED: string
  CHECKED: string
end

local record CheckboxHighlightProps
  GROUPS: CheckboxHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local CHECKBOX_HIGHLIGHT_GROUPS <const>: CheckboxHighlightGroupsProps = {
  UNCHECKED = 'ScaledMarkdownCheckboxUnchecked',
  CHECKED = 'ScaledMarkdownCheckboxChecked',
}

local CHECKBOX_HIGHLIGHT <const>: CheckboxHighlightProps = {
  GROUPS = CHECKBOX_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [CHECKBOX_HIGHLIGHT_GROUPS.UNCHECKED] = {
      link = '@markup.list.unchecked.markdown',
    },
    [CHECKBOX_HIGHLIGHT_GROUPS.CHECKED] = {
      link = '@markup.list.checked.markdown',
    },
  },
}

return CHECKBOX_HIGHLIGHT
