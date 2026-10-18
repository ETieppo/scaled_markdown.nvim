local BORDER_CHARSET = require('scaled_markdown.core.border.border_charset')
local utf8_text = require('scaled_markdown.core.text.utf8_text')

local TITLE_LEADING_FILL_WIDTH = 1

local border_line_builder = {}


local function build_columns_line(
   left,
   junction,
   right,
   column_widths)

   local parts = {}
   for column_index, column_width in ipairs(column_widths) do
      parts[column_index] = string.rep(BORDER_CHARSET.HORIZONTAL, column_width)
   end
   return left .. table.concat(parts, junction) .. right
end

function border_line_builder.build_top(width, title)
   local inner_width = math.max(0, width - 2)
   if not title or title == '' then
      return BORDER_CHARSET.TOP_LEFT ..
      string.rep(BORDER_CHARSET.HORIZONTAL, inner_width) ..
      BORDER_CHARSET.TOP_RIGHT
   end

   local leading_fill =
   string.rep(BORDER_CHARSET.HORIZONTAL, TITLE_LEADING_FILL_WIDTH)
   local title_part = leading_fill .. ' ' .. title .. ' '
   local trailing_width =
   math.max(0, inner_width - utf8_text.display_width(title_part))

   return BORDER_CHARSET.TOP_LEFT ..
   title_part ..
   string.rep(BORDER_CHARSET.HORIZONTAL, trailing_width) ..
   BORDER_CHARSET.TOP_RIGHT
end

function border_line_builder.build_bottom(width)
   local inner_width = math.max(0, width - 2)
   return BORDER_CHARSET.BOTTOM_LEFT ..
   string.rep(BORDER_CHARSET.HORIZONTAL, inner_width) ..
   BORDER_CHARSET.BOTTOM_RIGHT
end

function border_line_builder.build_grid_top(column_widths)
   return build_columns_line(
   BORDER_CHARSET.TOP_LEFT,
   BORDER_CHARSET.TOP_JUNCTION,
   BORDER_CHARSET.TOP_RIGHT,
   column_widths)

end

function border_line_builder.build_grid_separator(
   column_widths)

   return build_columns_line(
   BORDER_CHARSET.LEFT_JUNCTION,
   BORDER_CHARSET.CROSS_JUNCTION,
   BORDER_CHARSET.RIGHT_JUNCTION,
   column_widths)

end

function border_line_builder.build_grid_bottom(column_widths)
   return build_columns_line(
   BORDER_CHARSET.BOTTOM_LEFT,
   BORDER_CHARSET.BOTTOM_JUNCTION,
   BORDER_CHARSET.BOTTOM_RIGHT,
   column_widths)

end

function border_line_builder.vertical()
   return BORDER_CHARSET.VERTICAL end

return border_line_builder
